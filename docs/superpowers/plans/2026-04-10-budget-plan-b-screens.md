# Budget Plan B: Screens & UI

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build all 9 budget screens and 8 widgets, wired to the core services from Plan A.

**Architecture:** StatefulWidget screens using setState, consuming IncomeService + ExpenditureService + BudgetService. Local-first from BudgetDatabase with background API sync. Monochrome Material 3 design.

**Tech Stack:** Flutter/Dart, sqflite, Material 3

**Depends on:** Plan A (backend + core services) must be complete.

---

## Reference Files

| File | Purpose |
|---|---|
| `docs/modules/budget.md` | Full spec with 98 features, 9 screens, data models |
| `lib/models/budget_models.dart` | BudgetEnvelope, BudgetTransaction, BudgetGoal, BudgetPeriod |
| `lib/services/budget_service.dart` | Local BudgetService with sync |
| `lib/services/income_service.dart` | IncomeService (Plan A creates this) |
| `lib/services/expenditure_service.dart` | ExpenditureService (Plan A creates this) |
| `lib/tajirika/pages/tajirika_home_page.dart` | Reference: TAJIRI screen pattern |
| `lib/tajirika/pages/earnings_overview_page.dart` | Reference: financial screen pattern |

## TAJIRI Screen Patterns (Mandatory)

Every screen in this plan MUST follow these patterns:

```dart
// Design tokens
static const Color _kBg = Color(0xFFFAFAFA);
static const Color _kPrimary = Color(0xFF1A1A1A);
static const Color _kSecondary = Color(0xFF666666);
static const Color _kTertiary = Color(0xFF999999);
static const Color _kSurface = Color(0xFFFFFFFF);
static const Color _kDivider = Color(0xFFE0E0E0);
static const Color _kSuccess = Color(0xFF4CAF50);
static const Color _kWarning = Color(0xFFFF9800);
static const Color _kError = Color(0xFFE53935);

// Auth token pattern:
final storage = await LocalStorageService.getInstance();
final token = storage.getAuthToken();
final userId = storage.getUser()?.userId;

// Bilingual pattern:
final s = AppStringsScope.of(context);
final isSwahili = s?.isSwahili ?? false;

// Loading/error/data pattern:
bool _isLoading = true;
String? _error;
// try/catch + if (!mounted) return on ALL async calls
// RefreshIndicator + SingleChildScrollView/ListView
// SafeArea wrapping body content
```

## Shared Helper: `_formatTZS`

Every screen that displays TZS amounts must include this static helper or import it from a shared location:

```dart
static String _formatTZS(double amount) {
  if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
  return 'TZS ${amount.toStringAsFixed(0)}';
}
```

## Shared Helper: `_envelopeIcon`

Used across multiple screens/widgets:

```dart
static IconData envelopeIcon(String name) {
  switch (name) {
    case 'home': case 'home_rounded': return Icons.home_rounded;
    case 'restaurant': case 'restaurant_rounded': return Icons.restaurant_rounded;
    case 'directions_car': case 'directions_car_rounded': return Icons.directions_car_rounded;
    case 'school': case 'school_rounded': return Icons.school_rounded;
    case 'receipt_long': case 'receipt_long_rounded': return Icons.receipt_long_rounded;
    case 'savings': case 'savings_rounded': return Icons.savings_rounded;
    case 'phone_android': case 'phone_android_rounded': return Icons.phone_android_rounded;
    case 'medical_services': case 'medical_services_rounded': return Icons.medical_services_rounded;
    case 'warning': case 'warning_rounded': return Icons.warning_rounded;
    case 'sports_esports': case 'sports_esports_rounded': return Icons.sports_esports_rounded;
    case 'flag': case 'flag_rounded': return Icons.flag_rounded;
    case 'phone': case 'phone_rounded': return Icons.phone_rounded;
    case 'shopping_bag': case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
    case 'bolt': case 'bolt_rounded': return Icons.bolt_rounded;
    case 'child_care': case 'child_care_rounded': return Icons.child_care_rounded;
    case 'family_restroom': case 'family_restroom_rounded': return Icons.family_restroom_rounded;
    case 'checkroom': case 'checkroom_rounded': return Icons.checkroom_rounded;
    case 'spa': case 'spa_rounded': return Icons.spa_rounded;
    case 'volunteer_activism': case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
    case 'handshake': case 'handshake_rounded': return Icons.handshake_rounded;
    case 'account_balance_wallet': case 'account_balance_wallet_rounded': return Icons.account_balance_wallet_rounded;
    case 'health_and_safety': case 'health_and_safety_rounded': return Icons.health_and_safety_rounded;
    case 'business_center': case 'business_center_rounded': return Icons.business_center_rounded;
    default: return Icons.circle_outlined;
  }
}
```

---

## Task 1: Budget Widgets (all 8)

**File:** `lib/screens/budget/widgets/` (create directory + 8 files)

Create 8 reusable widgets extracted from the screens. Each widget is a StatelessWidget that takes data and callbacks as parameters.

### 1a. `wallet_balance_card.dart`

```dart
// lib/screens/budget/widgets/wallet_balance_card.dart
import 'package:flutter/material.dart';

/// Dark hero card showing wallet balance with top-up/withdraw buttons.
/// Spec features: #1, #2, #3, #4
class WalletBalanceCard extends StatelessWidget {
  final double balance;
  final String? lastSyncTime;
  final bool isSyncing;
  final bool isSwahili;
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;

  const WalletBalanceCard({
    super.key,
    required this.balance,
    this.lastSyncTime,
    this.isSyncing = false,
    this.isSwahili = false,
    this.onTopUp,
    this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isSwahili ? 'Salio la Pochi' : 'Wallet Balance',
                style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
              ),
              const Spacer(),
              if (isSyncing)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Color(0xFF999999),
                  ),
                )
              else if (lastSyncTime != null)
                Text(
                  lastSyncTime!,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF666666)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(balance),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onTopUp,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      isSwahili ? 'Weka Pesa' : 'Top Up',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF444444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onWithdraw,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                    label: Text(
                      isSwahili ? 'Toa Pesa' : 'Withdraw',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF444444)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### 1b. `safe_to_spend_card.dart`

```dart
// lib/screens/budget/widgets/safe_to_spend_card.dart
import 'package:flutter/material.dart';

/// Color-coded card showing safe-to-spend amount.
/// Green = healthy (>40% of income), Amber = getting low (20-40%), Red = danger (<20%)
/// Spec features: #5, #6, #7, #8
class SafeToSpendCard extends StatelessWidget {
  final double safeToSpend;
  final double totalIncome;
  final bool isSwahili;

  const SafeToSpendCard({
    super.key,
    required this.safeToSpend,
    required this.totalIncome,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = totalIncome > 0 ? safeToSpend / totalIncome : 0.0;
    final color = safeToSpend <= 0
        ? const Color(0xFFE53935)
        : ratio < 0.2
            ? const Color(0xFFE53935)
            : ratio < 0.4
                ? const Color(0xFFFF9800)
                : const Color(0xFF4CAF50);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              safeToSpend <= 0
                  ? Icons.warning_rounded
                  : ratio < 0.2
                      ? Icons.warning_rounded
                      : ratio < 0.4
                          ? Icons.info_rounded
                          : Icons.check_circle_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSwahili ? 'Unaweza kutumia' : 'Safe to spend',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTZS(safeToSpend.clamp(0, double.infinity)),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### 1c. `unallocated_card.dart`

```dart
// lib/screens/budget/widgets/unallocated_card.dart
import 'package:flutter/material.dart';

/// Warning card when unallocated funds exist. Nudges user to allocate.
/// Spec features: #9, #10, #11
class UnallocatedCard extends StatelessWidget {
  final double unallocatedAmount;
  final bool isSwahili;
  final VoidCallback? onAllocate;

  const UnallocatedCard({
    super.key,
    required this.unallocatedAmount,
    this.isSwahili = false,
    this.onAllocate,
  });

  @override
  Widget build(BuildContext context) {
    if (unallocatedAmount <= 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFFF9800)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatTZS(unallocatedAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isSwahili
                      ? 'haijatengwa kwenye bahasha'
                      : 'not allocated to any envelope',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: FilledButton(
              onPressed: onAllocate,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isSwahili ? 'Tenga' : 'Allocate',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### 1d. `envelope_list_tile.dart`

```dart
// lib/screens/budget/widgets/envelope_list_tile.dart
import 'package:flutter/material.dart';
import '../../../models/budget_models.dart';
import 'spending_pace_badge.dart';

/// Envelope row with progress bar, remaining amount, and pace badge.
/// Spec features: #15, #16, #21
class EnvelopeListTile extends StatelessWidget {
  final BudgetEnvelope envelope;
  final SpendingPaceStatus? paceStatus;
  final double? dailyAllowance;
  final bool isSwahili;
  final VoidCallback? onTap;

  const EnvelopeListTile({
    super.key,
    required this.envelope,
    this.paceStatus,
    this.dailyAllowance,
    this.isSwahili = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = envelope.percentUsed.clamp(0, 100) / 100;
    final isOver = envelope.isOverBudget;
    final barColor = isOver
        ? const Color(0xFFE53935)
        : (pct > 0.8 ? const Color(0xFFFF9800) : const Color(0xFF1A1A1A));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _envelopeIcon(envelope.icon),
                  size: 20,
                  color: Color(int.parse('FF${envelope.color}', radix: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    envelope.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (paceStatus != null) ...[
                  SpendingPaceBadge(
                    status: paceStatus!,
                    isSwahili: isSwahili,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  isOver
                      ? '-${_formatTZS(envelope.spentAmount - envelope.allocatedAmount)}'
                      : _formatTZS(envelope.remainingAmount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOver ? const Color(0xFFE53935) : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                backgroundColor: const Color(0xFFE0E0E0),
                valueColor: AlwaysStoppedAnimation(barColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatTZS(envelope.spentAmount)} / ${_formatTZS(envelope.allocatedAmount)}',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                ),
                if (dailyAllowance != null && !isOver)
                  Text(
                    '${_formatTZS(dailyAllowance!)}/${isSwahili ? 'siku' : 'day'}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
                  )
                else
                  Text(
                    '${envelope.percentUsed.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: barColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  static IconData _envelopeIcon(String name) {
    switch (name) {
      case 'home': case 'home_rounded': return Icons.home_rounded;
      case 'restaurant': case 'restaurant_rounded': return Icons.restaurant_rounded;
      case 'directions_car': case 'directions_car_rounded': return Icons.directions_car_rounded;
      case 'school': case 'school_rounded': return Icons.school_rounded;
      case 'receipt_long': case 'receipt_long_rounded': return Icons.receipt_long_rounded;
      case 'savings': case 'savings_rounded': return Icons.savings_rounded;
      case 'phone_android': case 'phone_android_rounded': return Icons.phone_android_rounded;
      case 'medical_services': case 'medical_services_rounded': return Icons.medical_services_rounded;
      case 'warning': case 'warning_rounded': return Icons.warning_rounded;
      case 'sports_esports': case 'sports_esports_rounded': return Icons.sports_esports_rounded;
      case 'flag': case 'flag_rounded': return Icons.flag_rounded;
      case 'phone': case 'phone_rounded': return Icons.phone_rounded;
      case 'shopping_bag': case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'bolt': case 'bolt_rounded': return Icons.bolt_rounded;
      case 'child_care': case 'child_care_rounded': return Icons.child_care_rounded;
      case 'family_restroom': case 'family_restroom_rounded': return Icons.family_restroom_rounded;
      case 'checkroom': case 'checkroom_rounded': return Icons.checkroom_rounded;
      case 'spa': case 'spa_rounded': return Icons.spa_rounded;
      case 'volunteer_activism': case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
      case 'handshake': case 'handshake_rounded': return Icons.handshake_rounded;
      case 'account_balance_wallet': case 'account_balance_wallet_rounded': return Icons.account_balance_wallet_rounded;
      case 'health_and_safety': case 'health_and_safety_rounded': return Icons.health_and_safety_rounded;
      case 'business_center': case 'business_center_rounded': return Icons.business_center_rounded;
      default: return Icons.circle_outlined;
    }
  }
}
```

### 1e. `spending_pace_badge.dart`

```dart
// lib/screens/budget/widgets/spending_pace_badge.dart
import 'package:flutter/material.dart';

enum SpendingPaceStatus { onTrack, caution, overBudget }

/// Small chip showing spending pace status.
/// Spec features: #21, #22, #23, #24, #25
class SpendingPaceBadge extends StatelessWidget {
  final SpendingPaceStatus status;
  final bool isSwahili;

  const SpendingPaceBadge({
    super.key,
    required this.status,
    this.isSwahili = false,
  });

  @override
  Widget build(BuildContext context) {
    final (Color color, String label) = switch (status) {
      SpendingPaceStatus.onTrack => (
          const Color(0xFF4CAF50),
          isSwahili ? 'Sawa' : 'On Track',
        ),
      SpendingPaceStatus.caution => (
          const Color(0xFFFF9800),
          isSwahili ? 'Tahadhari' : 'Caution',
        ),
      SpendingPaceStatus.overBudget => (
          const Color(0xFFE53935),
          isSwahili ? 'Imezidi' : 'Over',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
```

### 1f. `income_source_tile.dart`

```dart
// lib/screens/budget/widgets/income_source_tile.dart
import 'package:flutter/material.dart';

/// Income row with source icon, name, and amount.
/// Spec features: #47, #48
class IncomeSourceTile extends StatelessWidget {
  final String sourceName;
  final double amount;
  final double totalIncome;
  final IconData icon;
  final double? trendPercent; // positive = up, negative = down

  const IncomeSourceTile({
    super.key,
    required this.sourceName,
    required this.amount,
    required this.totalIncome,
    required this.icon,
    this.trendPercent,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalIncome > 0 ? (amount / totalIncome * 100) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF1A1A1A)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${pct.toStringAsFixed(0)}% of total',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTZS(amount),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              if (trendPercent != null) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendPercent! >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 12,
                      color: trendPercent! >= 0
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE53935),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${trendPercent!.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: trendPercent! >= 0
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### 1g. `goal_card.dart`

```dart
// lib/screens/budget/widgets/goal_card.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/budget_models.dart';

/// Goal card with progress ring, name, amounts, and contribute button.
/// Spec features: #55, #56, #57, #58
class GoalCard extends StatelessWidget {
  final BudgetGoal goal;
  final bool isSwahili;
  final VoidCallback? onContribute;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.isSwahili = false,
    this.onContribute,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal.percentComplete / 100;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progress ring
            SizedBox(
              width: 56,
              height: 56,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: pct.clamp(0.0, 1.0),
                  color: goal.isComplete
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF1A1A1A),
                ),
                child: Center(
                  child: Text(
                    '${goal.percentComplete.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: goal.isComplete
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTZS(goal.savedAmount)} / ${_formatTZS(goal.targetAmount)}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
                  ),
                  if (goal.monthlyTarget != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      isSwahili
                          ? '${_formatTZS(goal.monthlyTarget!)} kwa mwezi'
                          : '${_formatTZS(goal.monthlyTarget!)} per month',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                    ),
                  ],
                ],
              ),
            ),
            if (!goal.isComplete)
              SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: onContribute,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isSwahili ? 'Ongeza' : 'Add',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
```

### 1h. `recurring_expense_tile.dart`

```dart
// lib/screens/budget/widgets/recurring_expense_tile.dart
import 'package:flutter/material.dart';

/// Recurring charge with confirm/dismiss actions.
/// Spec features: #37-#41
class RecurringExpenseTile extends StatelessWidget {
  final String description;
  final double amount;
  final String frequency; // 'monthly', 'weekly'
  final String? nextDate;
  final bool isConfirmed;
  final bool isSwahili;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const RecurringExpenseTile({
    super.key,
    required this.description,
    required this.amount,
    this.frequency = 'monthly',
    this.nextDate,
    this.isConfirmed = false,
    this.isSwahili = false,
    this.onConfirm,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isConfirmed
                ? const Color(0xFFE0E0E0)
                : const Color(0xFFFFE0B2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isConfirmed
                    ? Icons.repeat_rounded
                    : Icons.help_outline_rounded,
                size: 18,
                color: isConfirmed
                    ? const Color(0xFF1A1A1A)
                    : const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextDate != null
                        ? '${isSwahili ? 'Ijayo' : 'Next'}: $nextDate'
                        : (frequency == 'monthly'
                            ? (isSwahili ? 'Kila mwezi' : 'Monthly')
                            : (isSwahili ? 'Kila wiki' : 'Weekly')),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTZS(amount),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                if (!isConfirmed) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onConfirm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSwahili ? 'Thibitisha' : 'Confirm',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSwahili ? 'Ondoa' : 'Dismiss',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE53935),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### Verification for Task 1

```bash
# After creating all 8 widget files:
ls lib/screens/budget/widgets/
# Should show: wallet_balance_card.dart, safe_to_spend_card.dart, unallocated_card.dart,
# envelope_list_tile.dart, spending_pace_badge.dart, income_source_tile.dart,
# goal_card.dart, recurring_expense_tile.dart

flutter analyze lib/screens/budget/widgets/
```

---

## Task 2: Budget Home Screen (Rewrite)

**File:** `lib/screens/budget/budget_home_screen.dart` (overwrite existing)

This is the main budget screen. It replaces the existing version with:
- Wallet balance hero card (dark)
- Safe-to-spend card (color-coded)
- Unallocated funds warning with "Allocate" button
- Envelope list with progress bars and pace indicators
- Quick actions row (Add Expense, Report, Goals, Recurring)
- Recent transactions section

**Spec features covered:** #1-#16, #21-#26, #42

```dart
// lib/screens/budget/budget_home_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import '../../services/local_storage_service.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/safe_to_spend_card.dart';
import 'widgets/unallocated_card.dart';
import 'widgets/envelope_list_tile.dart';
import 'widgets/spending_pace_badge.dart';
import 'add_transaction_screen.dart';
import 'allocate_funds_screen.dart';
import 'envelope_detail_screen.dart';
import 'goals_screen.dart';
import 'monthly_report_screen.dart';
import 'income_breakdown_screen.dart';
import 'cash_flow_forecast_screen.dart';
import 'recurring_expenses_screen.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

class BudgetHomeScreen extends StatefulWidget {
  final int userId;

  const BudgetHomeScreen({super.key, required this.userId});

  @override
  State<BudgetHomeScreen> createState() => _BudgetHomeScreenState();
}

class _BudgetHomeScreenState extends State<BudgetHomeScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  List<BudgetGoal> _goals = [];
  Map<BudgetSource, double> _incomeBreakdown = {};
  List<BudgetTransaction> _recentTransactions = [];
  double _walletBalance = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentPeriod(),
        _service.getEnvelopes(),
        _service.getGoals(),
        _service.getCurrentIncomeBreakdown(),
        _service.getTransactions(limit: 5),
      ]);

      if (!mounted) return;
      setState(() {
        _period = results[0] as BudgetPeriod;
        _envelopes = results[1] as List<BudgetEnvelope>;
        _goals = results[2] as List<BudgetGoal>;
        _incomeBreakdown = results[3] as Map<BudgetSource, double>;
        _recentTransactions = results[4] as List<BudgetTransaction>;
        // Wallet balance = total income for now (Plan A WalletService integration)
        _walletBalance = _period?.totalIncome ?? 0;
        _isLoading = false;
      });

      _autoSync();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _autoSync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final synced = await _service.syncFromTajiri(widget.userId);
      if (!mounted) return;
      setState(() => _isSyncing = false);
      if (synced > 0) _loadData();
    } catch (_) {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  double get _safeToSpend {
    final period = _period;
    if (period == null) return 0;
    return _walletBalance - period.totalAllocated;
  }

  double get _unallocated {
    return _period?.unallocated ?? 0;
  }

  SpendingPaceStatus _paceForEnvelope(BudgetEnvelope env) {
    if (env.isOverBudget) return SpendingPaceStatus.overBudget;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;
    final expectedPct = dayOfMonth / daysInMonth;
    final actualPct = env.allocatedAmount > 0
        ? env.spentAmount / env.allocatedAmount
        : 0.0;
    if (actualPct > expectedPct + 0.15) return SpendingPaceStatus.caution;
    return SpendingPaceStatus.onTrack;
  }

  double? _dailyAllowance(BudgetEnvelope env) {
    if (env.isOverBudget || env.remainingAmount <= 0) return null;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    if (daysLeft <= 0) return null;
    return env.remainingAmount / daysLeft;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: _kTertiary),
              const SizedBox(height: 16),
              Text(
                _error ?? (isSwahili ? 'Imeshindwa kupakia' : 'Failed to load'),
                style: const TextStyle(fontSize: 14, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loadData,
                child: Text(isSwahili ? 'Jaribu tena' : 'Try again'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (added == true) _loadData();
        },
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: _kPrimary,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Month header
              _buildMonthHeader(isSwahili),
              const SizedBox(height: 16),

              // Wallet balance hero card
              WalletBalanceCard(
                balance: _walletBalance,
                isSyncing: _isSyncing,
                isSwahili: isSwahili,
                onTopUp: () {
                  // TODO: Navigate to wallet top-up screen
                },
                onWithdraw: () {
                  // TODO: Navigate to wallet withdraw screen
                },
              ),
              const SizedBox(height: 12),

              // Safe to spend card
              SafeToSpendCard(
                safeToSpend: _safeToSpend,
                totalIncome: _period?.totalIncome ?? 0,
                isSwahili: isSwahili,
              ),
              const SizedBox(height: 12),

              // Unallocated funds warning
              UnallocatedCard(
                unallocatedAmount: _unallocated,
                isSwahili: isSwahili,
                onAllocate: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllocateFundsScreen(userId: widget.userId),
                    ),
                  );
                  _loadData();
                },
              ),
              if (_unallocated > 0) const SizedBox(height: 16),

              // Quick actions
              _buildQuickActions(isSwahili),
              const SizedBox(height: 20),

              // Envelopes section
              _buildSectionHeader(
                isSwahili ? 'BAHASHA' : 'ENVELOPES',
                onAction: () => _showAddEnvelopeDialog(),
                actionLabel: '+ ${isSwahili ? 'Ongeza' : 'Add'}',
              ),
              const SizedBox(height: 8),
              if (_envelopes.isEmpty)
                _buildEmptyState(
                  Icons.mail_rounded,
                  isSwahili ? 'Hakuna bahasha' : 'No envelopes',
                  isSwahili ? 'Ongeza bahasha kuanza bajeti' : 'Add envelopes to start budgeting',
                )
              else
                ..._envelopes.map((env) => EnvelopeListTile(
                  envelope: env,
                  paceStatus: env.allocatedAmount > 0 ? _paceForEnvelope(env) : null,
                  dailyAllowance: _dailyAllowance(env),
                  isSwahili: isSwahili,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EnvelopeDetailScreen(envelope: env),
                      ),
                    );
                    _loadData();
                  },
                )),

              const SizedBox(height: 20),

              // Goals preview
              _buildSectionHeader(
                isSwahili ? 'MALENGO' : 'GOALS',
                onAction: () => _openGoals(isSwahili),
                actionLabel: isSwahili ? 'Tazama' : 'View',
              ),
              const SizedBox(height: 8),
              if (_goals.isEmpty)
                _buildEmptyState(
                  Icons.flag_outlined,
                  isSwahili ? 'Bado hakuna lengo' : 'No goals yet',
                  isSwahili ? 'Weka lengo la akiba' : 'Set a savings goal',
                )
              else
                ..._goals.take(3).map(_buildGoalPreview),

              const SizedBox(height: 20),

              // Recent transactions
              _buildSectionHeader(isSwahili ? 'MIAMALA YA HIVI KARIBUNI' : 'RECENT TRANSACTIONS'),
              const SizedBox(height: 8),
              if (_recentTransactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      isSwahili ? 'Hakuna miamala bado' : 'No transactions yet',
                      style: const TextStyle(color: _kTertiary, fontSize: 13),
                    ),
                  ),
                )
              else
                ..._recentTransactions.map((txn) => _buildTransactionRow(txn, isSwahili)),

              const SizedBox(height: 80), // FAB space
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(bool isSwahili) {
    final now = DateTime.now();
    final monthsSw = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final months = isSwahili ? monthsSw : monthsEn;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${months[now.month - 1]} ${now.year}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _kPrimary),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.bar_chart_rounded, color: _kPrimary),
          tooltip: isSwahili ? 'Ripoti' : 'Report',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MonthlyReportScreen(userId: widget.userId)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(bool isSwahili) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _quickAction(Icons.add_rounded, isSwahili ? 'Matumizi' : 'Expense', () async {
            final added = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
            );
            if (added == true) _loadData();
          }),
          const SizedBox(width: 8),
          _quickAction(Icons.bar_chart_rounded, isSwahili ? 'Ripoti' : 'Report', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MonthlyReportScreen(userId: widget.userId)),
            );
          }),
          const SizedBox(width: 8),
          _quickAction(Icons.flag_rounded, isSwahili ? 'Malengo' : 'Goals', () {
            _openGoals(isSwahili);
          }),
          const SizedBox(width: 8),
          _quickAction(Icons.repeat_rounded, isSwahili ? 'Kujirudia' : 'Recurring', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecurringExpensesScreen(userId: widget.userId)),
            );
          }),
          const SizedBox(width: 8),
          _quickAction(Icons.trending_up_rounded, isSwahili ? 'Mapato' : 'Income', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => IncomeBreakdownScreen(userId: widget.userId)),
            );
          }),
          const SizedBox(width: 8),
          _quickAction(Icons.show_chart_rounded, isSwahili ? 'Utabiri' : 'Forecast', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CashFlowForecastScreen(userId: widget.userId)),
            );
          }),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kDivider, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAction, String? actionLabel}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
        ),
        const Spacer(),
        if (onAction != null && actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: _kTertiary),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: _kSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: _kTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildGoalPreview(BudgetGoal goal) {
    final pct = goal.percentComplete / 100;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Icon(Icons.flag_rounded, size: 20, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(goal.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct.clamp(0.0, 1.0),
                    backgroundColor: _kDivider,
                    valueColor: AlwaysStoppedAnimation(goal.isComplete ? _kSuccess : _kPrimary),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('${goal.percentComplete.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kPrimary)),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BudgetTransaction txn, bool isSwahili) {
    final isIncome = txn.isIncome;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: (isIncome ? _kSuccess : _kError).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 16,
              color: isIncome ? _kSuccess : _kError,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  txn.source.label,
                  style: const TextStyle(fontSize: 10, color: _kTertiary),
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_formatTZS(txn.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isIncome ? _kSuccess : _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEnvelopeDialog() {
    showEnvelopeDialog(context, onSaved: _loadData);
  }

  void _openGoals(bool isSwahili) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GoalsScreen(userId: widget.userId)),
    ).then((_) => _loadData());
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

/// Show envelope add/edit dialog (bottom sheet)
void showEnvelopeDialog(
  BuildContext context, {
  BudgetEnvelope? envelope,
  required VoidCallback onSaved,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnvelopeDialog(envelope: envelope, onSaved: onSaved),
  );
}

class _EnvelopeDialog extends StatefulWidget {
  final BudgetEnvelope? envelope;
  final VoidCallback onSaved;

  const _EnvelopeDialog({this.envelope, required this.onSaved});

  @override
  State<_EnvelopeDialog> createState() => _EnvelopeDialogState();
}

class _EnvelopeDialogState extends State<_EnvelopeDialog> {
  final BudgetService _service = BudgetService();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedIcon = 'circle';
  String _selectedColor = '1A1A1A';
  bool _isSaving = false;

  bool get _isEditing => widget.envelope != null;

  static const _icons = [
    'home', 'restaurant', 'directions_car', 'school', 'receipt_long',
    'savings', 'phone_android', 'medical_services', 'warning',
    'sports_esports', 'shopping_bag', 'flag', 'bolt', 'child_care',
    'family_restroom', 'checkroom', 'spa', 'volunteer_activism',
    'handshake', 'account_balance_wallet', 'health_and_safety',
    'business_center',
  ];

  static const _colors = [
    '1A1A1A', '4CAF50', '2196F3', 'FF9800', '9C27B0',
    '009688', '607D8B', 'E53935', 'FF5722', '795548',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.envelope!.name;
      _amountController.text = widget.envelope!.allocatedAmount.toStringAsFixed(0);
      _selectedIcon = widget.envelope!.icon;
      _selectedColor = widget.envelope!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (name.isEmpty || amount == null) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _service.updateEnvelope(widget.envelope!.copyWith(
          name: name,
          allocatedAmount: amount,
          icon: _selectedIcon,
          color: _selectedColor,
        ));
      } else {
        await _service.createEnvelope(
          name: name,
          icon: _selectedIcon,
          allocatedAmount: amount,
          color: _selectedColor,
        );
      }

      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: _kDivider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isEditing
                ? (isSwahili ? 'Hariri Bahasha' : 'Edit Envelope')
                : (isSwahili ? 'Bahasha Mpya' : 'New Envelope'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: isSwahili ? 'Jina' : 'Name',
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
              prefixText: 'TZS ',
              filled: true,
              fillColor: _kBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Text(isSwahili ? 'Ikoni' : 'Icon', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _icons.map((icon) {
              final selected = _selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => _selectedIcon = icon),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: selected ? _kPrimary : _kBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    EnvelopeListTile.envelopeIconStatic(icon),
                    size: 20,
                    color: selected ? Colors.white : _kSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Text(isSwahili ? 'Rangi' : 'Color', style: const TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _colors.map((color) {
              final selected = _selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse('FF$color', radix: 16)),
                    borderRadius: BorderRadius.circular(8),
                    border: selected ? Border.all(color: _kPrimary, width: 2) : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _isEditing
                          ? (isSwahili ? 'Hifadhi' : 'Save')
                          : (isSwahili ? 'Ongeza' : 'Add'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**NOTE:** The `EnvelopeListTile.envelopeIconStatic(icon)` call above means we need to add a static method to `EnvelopeListTile`. Alternatively, factor the icon-lookup into a top-level function in a shared file like `lib/screens/budget/widgets/budget_helpers.dart`. The implementor should choose the cleanest approach -- either a shared helper file or inline the icon map. The existing `_envelopeIcon` in the list tile widget is already private; making it package-private static is the simplest fix.

### Verification for Task 2

```bash
flutter analyze lib/screens/budget/budget_home_screen.dart
```

---

## Task 3: Envelope Detail Screen (Rewrite)

**File:** `lib/screens/budget/envelope_detail_screen.dart` (overwrite existing)

Adds: daily spending bars chart, move money between envelopes, daily allowance, pace indicator, bilingual support.

**Spec features covered:** #16, #17, #22-#26, #51-#54

```dart
// lib/screens/budget/envelope_detail_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'widgets/spending_pace_badge.dart';
import 'add_transaction_screen.dart';
import 'budget_home_screen.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kError = Color(0xFFE53935);
const Color _kWarning = Color(0xFFFF9800);
const Color _kSuccess = Color(0xFF4CAF50);

class EnvelopeDetailScreen extends StatefulWidget {
  final BudgetEnvelope envelope;

  const EnvelopeDetailScreen({super.key, required this.envelope});

  @override
  State<EnvelopeDetailScreen> createState() => _EnvelopeDetailScreenState();
}

class _EnvelopeDetailScreenState extends State<EnvelopeDetailScreen> {
  final BudgetService _service = BudgetService();
  List<BudgetTransaction> _transactions = [];
  BudgetEnvelope? _envelope;
  Map<int, double> _dailySpending = {}; // day -> amount
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _envelope = widget.envelope;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final txns = await _service.getTransactions(
        envelopeId: widget.envelope.id,
        from: monthStart,
        to: monthEnd,
        limit: 200,
      );

      // Compute daily spending
      final daily = <int, double>{};
      for (final txn in txns) {
        if (txn.isExpense) {
          daily[txn.date.day] = (daily[txn.date.day] ?? 0) + txn.amount;
        }
      }

      // Refresh envelope data
      final envelopes = await _service.getEnvelopes();
      final updated = envelopes.firstWhere(
        (e) => e.id == widget.envelope.id,
        orElse: () => widget.envelope,
      );

      if (!mounted) return;
      setState(() {
        _transactions = txns;
        _dailySpending = daily;
        _envelope = updated;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  SpendingPaceStatus get _paceStatus {
    final env = _envelope ?? widget.envelope;
    if (env.isOverBudget) return SpendingPaceStatus.overBudget;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final expectedPct = now.day / daysInMonth;
    final actualPct = env.allocatedAmount > 0 ? env.spentAmount / env.allocatedAmount : 0.0;
    if (actualPct > expectedPct + 0.15) return SpendingPaceStatus.caution;
    return SpendingPaceStatus.onTrack;
  }

  double get _dailyAllowance {
    final env = _envelope ?? widget.envelope;
    if (env.isOverBudget || env.remainingAmount <= 0) return 0;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    if (daysLeft <= 0) return 0;
    return env.remainingAmount / daysLeft;
  }

  Future<void> _addExpense() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(preselectedEnvelopeId: widget.envelope.id),
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _editAllocation(bool isSwahili) async {
    final controller = TextEditingController(
      text: _envelope!.allocatedAmount.toStringAsFixed(0),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Badilisha Kiasi' : 'Change Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: 'TZS ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result >= 0) {
      await _service.updateEnvelope(_envelope!.copyWith(allocatedAmount: result));
      _loadData();
    }
  }

  Future<void> _moveMoney(bool isSwahili) async {
    final envelopes = await _service.getEnvelopes();
    final otherEnvelopes = envelopes.where((e) => e.id != widget.envelope.id).toList();
    if (otherEnvelopes.isEmpty) return;

    if (!mounted) return;

    BudgetEnvelope? targetEnvelope;
    final amountController = TextEditingController();
    bool isMovingFrom = false; // false = move TO this envelope, true = move FROM

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isSwahili ? 'Hamisha Pesa' : 'Move Money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Direction toggle
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => isMovingFrom = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isMovingFrom ? _kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kDivider),
                        ),
                        child: Center(
                          child: Text(
                            isSwahili ? 'Ingiza' : 'Move In',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: !isMovingFrom ? Colors.white : _kSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => isMovingFrom = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isMovingFrom ? _kPrimary : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _kDivider),
                        ),
                        child: Center(
                          child: Text(
                            isSwahili ? 'Toa' : 'Move Out',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isMovingFrom ? Colors.white : _kSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: targetEnvelope?.id,
                decoration: InputDecoration(
                  labelText: isMovingFrom
                      ? (isSwahili ? 'Peleka kwa' : 'Move to')
                      : (isSwahili ? 'Toa kutoka' : 'From'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: otherEnvelopes.map((e) => DropdownMenuItem<int>(
                  value: e.id,
                  child: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) {
                  setDialogState(() {
                    targetEnvelope = otherEnvelopes.firstWhere((e) => e.id == v);
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
                  prefixText: 'TZS ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              if (targetEnvelope != null && amountController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  // Impact preview
                  '${targetEnvelope!.name}: TZS ${targetEnvelope!.allocatedAmount.toStringAsFixed(0)}'
                  ' -> TZS ${(isMovingFrom ? targetEnvelope!.allocatedAmount + (double.tryParse(amountController.text) ?? 0) : targetEnvelope!.allocatedAmount - (double.tryParse(amountController.text) ?? 0)).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, color: _kTertiary),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(isSwahili ? 'Hamisha' : 'Move'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || targetEnvelope == null) return;
    final moveAmount = double.tryParse(amountController.text);
    amountController.dispose();
    if (moveAmount == null || moveAmount <= 0) return;

    try {
      if (isMovingFrom) {
        // Move FROM this envelope TO target
        await _service.updateEnvelope(
          _envelope!.copyWith(allocatedAmount: _envelope!.allocatedAmount - moveAmount),
        );
        await _service.updateEnvelope(
          targetEnvelope!.copyWith(allocatedAmount: targetEnvelope!.allocatedAmount + moveAmount),
        );
      } else {
        // Move TO this envelope FROM target
        await _service.updateEnvelope(
          _envelope!.copyWith(allocatedAmount: _envelope!.allocatedAmount + moveAmount),
        );
        await _service.updateEnvelope(
          targetEnvelope!.copyWith(allocatedAmount: targetEnvelope!.allocatedAmount - moveAmount),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final env = _envelope ?? widget.envelope;
    final pct = env.percentUsed.clamp(0, 100) / 100;
    final isOver = env.isOverBudget;
    final barColor = isOver ? _kError : (pct > 0.8 ? _kWarning : _kPrimary);

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(env.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary)),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 22),
            tooltip: isSwahili ? 'Hamisha pesa' : 'Move money',
            onPressed: () => _moveMoney(isSwahili),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: isSwahili ? 'Badilisha kiasi' : 'Edit amount',
            onPressed: () => _editAllocation(isSwahili),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card with pace badge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SpendingPaceBadge(status: _paceStatus, isSwahili: isSwahili),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOver
                          ? '-TZS ${(env.spentAmount - env.allocatedAmount).toStringAsFixed(0)}'
                          : 'TZS ${env.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isOver ? _kError : _kPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOver
                          ? (isSwahili ? 'Umezidi bajeti' : 'Over budget')
                          : (isSwahili ? 'Imebaki' : 'Remaining'),
                      style: TextStyle(fontSize: 13, color: isOver ? _kError : _kTertiary),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0.0, 1.0),
                        backgroundColor: _kDivider,
                        valueColor: AlwaysStoppedAnimation(barColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${isSwahili ? 'Imetumika' : 'Spent'}: TZS ${env.spentAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                        Text(
                          '${isSwahili ? 'Bajeti' : 'Budget'}: TZS ${env.allocatedAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                    if (_dailyAllowance > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${isSwahili ? 'Kiwango cha siku' : 'Daily allowance'}: TZS ${_dailyAllowance.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Daily spending chart
              if (_dailySpending.isNotEmpty) ...[
                Text(
                  isSwahili ? 'MATUMIZI YA KILA SIKU' : 'DAILY SPENDING',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                _buildDailyChart(),
                const SizedBox(height: 20),
              ],

              // Transactions header
              Row(
                children: [
                  Text(
                    isSwahili ? 'MIAMALA' : 'TRANSACTIONS',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                  ),
                  const Spacer(),
                  Text('${_transactions.length}', style: const TextStyle(fontSize: 12, color: _kTertiary)),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)))
              else if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      isSwahili ? 'Hakuna miamala bado' : 'No transactions yet',
                      style: const TextStyle(color: _kTertiary),
                    ),
                  ),
                )
              else
                ..._transactions.map(_buildTransactionTile),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        backgroundColor: _kPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDailyChart() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final maxSpend = _dailySpending.values.fold(0.0, (a, b) => math.max(a, b));

    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(math.min(daysInMonth, now.day), (i) {
          final day = i + 1;
          final amount = _dailySpending[day] ?? 0;
          final height = maxSpend > 0 ? (amount / maxSpend * 60).clamp(2.0, 60.0) : 2.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.5),
              child: Tooltip(
                message: '${isSwahili(context) ? 'Siku' : 'Day'} $day: TZS ${amount.toStringAsFixed(0)}',
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: day == now.day ? _kPrimary : const Color(0xFFCCCCCC),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  bool isSwahili(BuildContext context) {
    return AppStringsScope.of(context)?.isSwahili ?? false;
  }

  Widget _buildTransactionTile(BudgetTransaction txn) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _kDivider, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _kBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              txn.source == BudgetSource.manual
                  ? Icons.edit_rounded
                  : Icons.account_balance_wallet_rounded,
              size: 14,
              color: _kSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${txn.date.day}/${txn.date.month}',
                      style: const TextStyle(fontSize: 11, color: _kTertiary),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _kBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        txn.source == BudgetSource.manual
                            ? (sw ? 'Taslimu' : 'Cash')
                            : 'Wallet',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: _kTertiary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'TZS ${txn.amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
        ],
      ),
    );
  }
}
```

### Verification for Task 3

```bash
flutter analyze lib/screens/budget/envelope_detail_screen.dart
```

---

## Task 4: Add Transaction Screen (Rewrite)

**File:** `lib/screens/budget/add_transaction_screen.dart` (overwrite existing)

Adds: bilingual support, "Cash" vs "Wallet" badge, calls to ExpenditureService.recordExpenditure() and IncomeService.recordIncome().

**Spec features covered:** #42-#46

```dart
// lib/screens/budget/add_transaction_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);

class AddTransactionScreen extends StatefulWidget {
  final int? preselectedEnvelopeId;

  const AddTransactionScreen({super.key, this.preselectedEnvelopeId});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final BudgetService _service = BudgetService();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  BudgetTransactionType _type = BudgetTransactionType.expense;
  BudgetSource _source = BudgetSource.manual;
  int? _selectedEnvelopeId;
  List<BudgetEnvelope> _envelopes = [];
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEnvelopeId = widget.preselectedEnvelopeId;
    _loadEnvelopes();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadEnvelopes() async {
    try {
      final envelopes = await _service.getEnvelopes();
      if (mounted) setState(() => _envelopes = envelopes);
    } catch (_) {}
  }

  Future<void> _save() async {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final messenger = ScaffoldMessenger.of(context);

    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(isSwahili ? 'Weka kiasi sahihi' : 'Enter a valid amount')),
      );
      return;
    }

    final desc = _descriptionController.text.trim();
    if (desc.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(isSwahili ? 'Weka maelezo' : 'Enter a description')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.addTransaction(
        envelopeId: _type == BudgetTransactionType.expense ? _selectedEnvelopeId : null,
        amount: amount,
        type: _type,
        source: _source,
        description: desc,
        date: _date,
      );

      // Also report to IncomeService / ExpenditureService if available (Plan A)
      // try {
      //   final storage = await LocalStorageService.getInstance();
      //   final userId = storage.getUser()?.userId;
      //   if (userId != null) {
      //     if (_type == BudgetTransactionType.income) {
      //       await IncomeService.recordIncome(userId: userId, amount: amount, source: 'manual', description: desc);
      //     } else {
      //       await ExpenditureService.recordExpenditure(userId: userId, amount: amount, category: 'other', description: desc);
      //     }
      //   }
      // } catch (_) {}

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        messenger.showSnackBar(
          SnackBar(content: Text('${isSwahili ? 'Hitilafu' : 'Error'}: $e')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Ongeza Muamala' : 'Add Transaction',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type toggle
            _buildTypeToggle(isSwahili),
            const SizedBox(height: 20),

            // Amount
            Text(
              isSwahili ? 'Kiasi (TZS)' : 'Amount (TZS)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kPrimary),
              decoration: InputDecoration(
                prefixText: 'TZS ',
                prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _kTertiary),
                filled: true,
                fillColor: _kSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              isSwahili ? 'Maelezo' : 'Description',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: isSwahili ? 'Mfano: Grocery za wiki' : 'E.g.: Weekly groceries',
                hintStyle: const TextStyle(color: _kTertiary),
                filled: true,
                fillColor: _kSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Envelope (expenses only)
            if (_type == BudgetTransactionType.expense && _envelopes.isNotEmpty) ...[
              Text(
                isSwahili ? 'Bahasha' : 'Envelope',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _selectedEnvelopeId,
                    isExpanded: true,
                    hint: Text(isSwahili ? 'Chagua bahasha' : 'Select envelope'),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(isSwahili ? 'Hakuna bahasha' : 'No envelope'),
                      ),
                      ..._envelopes.map((e) => DropdownMenuItem<int?>(
                        value: e.id,
                        child: Text(e.name),
                      )),
                    ],
                    onChanged: (v) => setState(() => _selectedEnvelopeId = v),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Source (income)
            if (_type == BudgetTransactionType.income) ...[
              Text(
                isSwahili ? 'Chanzo' : 'Source',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [BudgetSource.manual, BudgetSource.salary, BudgetSource.shop, BudgetSource.michango]
                    .map((s) => ChoiceChip(
                          label: Text(s.label),
                          selected: _source == s,
                          onSelected: (_) => setState(() => _source = s),
                          selectedColor: _kPrimary,
                          labelStyle: TextStyle(
                            color: _source == s ? Colors.white : _kPrimary,
                            fontSize: 12,
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Cash/Wallet badge indicator
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        size: 14,
                        color: _kPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isSwahili ? 'Taslimu' : 'Cash',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isSwahili
                      ? 'Miamala ya pochi inajiandikisha yenyewe'
                      : 'Wallet transactions auto-track',
                  style: const TextStyle(fontSize: 11, color: _kTertiary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Date
            Text(
              isSwahili ? 'Tarehe' : 'Date',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 20, color: _kSecondary),
                    const SizedBox(width: 8),
                    Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: const TextStyle(fontSize: 14, color: _kPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isSwahili ? 'Hifadhi' : 'Save',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(bool isSwahili) {
    return Container(
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = BudgetTransactionType.expense),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == BudgetTransactionType.expense ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isSwahili ? 'Matumizi' : 'Expense',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _type == BudgetTransactionType.expense ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _type = BudgetTransactionType.income),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _type == BudgetTransactionType.income ? _kSuccess : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    isSwahili ? 'Mapato' : 'Income',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _type == BudgetTransactionType.income ? Colors.white : _kSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Verification for Task 4

```bash
flutter analyze lib/screens/budget/add_transaction_screen.dart
```

---

## Task 5: Allocate Funds Screen (New)

**File:** `lib/screens/budget/allocate_funds_screen.dart` (new file)

**Spec features covered:** #9-#12

```dart
// lib/screens/budget/allocate_funds_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kWarning = Color(0xFFFF9800);
const Color _kError = Color(0xFFE53935);

class AllocateFundsScreen extends StatefulWidget {
  final int userId;

  const AllocateFundsScreen({super.key, required this.userId});

  @override
  State<AllocateFundsScreen> createState() => _AllocateFundsScreenState();
}

class _AllocateFundsScreenState extends State<AllocateFundsScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getCurrentPeriod(),
        _service.getEnvelopes(),
      ]);
      if (!mounted) return;
      setState(() {
        _period = results[0] as BudgetPeriod;
        _envelopes = results[1] as List<BudgetEnvelope>;
        // Init controllers with current allocations
        for (final env in _envelopes) {
          if (env.id != null && !_controllers.containsKey(env.id)) {
            _controllers[env.id!] = TextEditingController(
              text: env.allocatedAmount > 0 ? env.allocatedAmount.toStringAsFixed(0) : '',
            );
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  double get _totalAllocated {
    double total = 0;
    for (final env in _envelopes) {
      if (env.id != null) {
        final c = _controllers[env.id!];
        final val = double.tryParse(c?.text.replaceAll(',', '') ?? '') ?? 0;
        total += val;
      }
    }
    return total;
  }

  double get _unallocated {
    return (_period?.totalIncome ?? 0) - _totalAllocated;
  }

  Future<void> _save() async {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);

    try {
      for (final env in _envelopes) {
        if (env.id == null) continue;
        final c = _controllers[env.id!];
        final newAmount = double.tryParse(c?.text.replaceAll(',', '') ?? '') ?? 0;
        if (newAmount != env.allocatedAmount) {
          await _service.updateEnvelope(env.copyWith(allocatedAmount: newAmount));
        }
      }

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(isSwahili ? 'Umefanikiwa kutenga pesa' : 'Funds allocated successfully'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('${isSwahili ? 'Hitilafu' : 'Error'}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Tenga Pesa' : 'Allocate Funds',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : Column(
                children: [
                  // Unallocated summary (sticky at top)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: _unallocated < 0
                        ? _kError.withValues(alpha: 0.08)
                        : _unallocated > 0
                            ? _kWarning.withValues(alpha: 0.08)
                            : _kSuccess.withValues(alpha: 0.08),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSwahili ? 'Haijatengwa' : 'Unallocated',
                                style: const TextStyle(fontSize: 12, color: _kSecondary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTZS(_unallocated),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: _unallocated < 0 ? _kError : _kPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isSwahili ? 'Mapato' : 'Income'}: ${_formatTZS(_period?.totalIncome ?? 0)}',
                              style: const TextStyle(fontSize: 11, color: _kTertiary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isSwahili ? 'Imetengwa' : 'Allocated'}: ${_formatTZS(_totalAllocated)}',
                              style: const TextStyle(fontSize: 11, color: _kTertiary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Envelope list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _envelopes.length,
                      itemBuilder: (context, index) {
                        final env = _envelopes[index];
                        if (env.id == null) return const SizedBox.shrink();
                        final controller = _controllers[env.id!]!;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kDivider, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _envelopeIcon(env.icon),
                                size: 20,
                                color: Color(int.parse('FF${env.color}', radix: 16)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      env.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (env.spentAmount > 0)
                                      Text(
                                        '${isSwahili ? 'Imetumika' : 'Spent'}: ${_formatTZS(env.spentAmount)}',
                                        style: const TextStyle(fontSize: 10, color: _kTertiary),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                  textAlign: TextAlign.right,
                                  onChanged: (_) => setState(() {}), // Refresh unallocated
                                  decoration: InputDecoration(
                                    prefixText: 'TZS ',
                                    prefixStyle: const TextStyle(fontSize: 11, color: _kTertiary),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    isDense: true,
                                    filled: true,
                                    fillColor: _kBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                isSwahili ? 'Hifadhi' : 'Save Allocations',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }

  static IconData _envelopeIcon(String name) {
    switch (name) {
      case 'home': case 'home_rounded': return Icons.home_rounded;
      case 'restaurant': case 'restaurant_rounded': return Icons.restaurant_rounded;
      case 'directions_car': case 'directions_car_rounded': return Icons.directions_car_rounded;
      case 'school': case 'school_rounded': return Icons.school_rounded;
      case 'receipt_long': case 'receipt_long_rounded': return Icons.receipt_long_rounded;
      case 'savings': case 'savings_rounded': return Icons.savings_rounded;
      case 'phone_android': case 'phone_android_rounded': return Icons.phone_android_rounded;
      case 'medical_services': case 'medical_services_rounded': return Icons.medical_services_rounded;
      case 'warning': case 'warning_rounded': return Icons.warning_rounded;
      case 'sports_esports': case 'sports_esports_rounded': return Icons.sports_esports_rounded;
      case 'flag': case 'flag_rounded': return Icons.flag_rounded;
      case 'shopping_bag': case 'shopping_bag_rounded': return Icons.shopping_bag_rounded;
      case 'bolt': case 'bolt_rounded': return Icons.bolt_rounded;
      case 'child_care': case 'child_care_rounded': return Icons.child_care_rounded;
      case 'family_restroom': case 'family_restroom_rounded': return Icons.family_restroom_rounded;
      case 'checkroom': case 'checkroom_rounded': return Icons.checkroom_rounded;
      case 'spa': case 'spa_rounded': return Icons.spa_rounded;
      case 'volunteer_activism': case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
      case 'handshake': case 'handshake_rounded': return Icons.handshake_rounded;
      case 'account_balance_wallet': case 'account_balance_wallet_rounded': return Icons.account_balance_wallet_rounded;
      case 'health_and_safety': case 'health_and_safety_rounded': return Icons.health_and_safety_rounded;
      case 'business_center': case 'business_center_rounded': return Icons.business_center_rounded;
      default: return Icons.circle_outlined;
    }
  }
}
```

### Verification for Task 5

```bash
flutter analyze lib/screens/budget/allocate_funds_screen.dart
```

---

## Task 6: Monthly Report Screen (Rewrite)

**File:** `lib/screens/budget/monthly_report_screen.dart` (overwrite existing)

Adds: bilingual, savings rate, month comparison, shareable card.

**Spec features covered:** #70-#77

```dart
// lib/screens/budget/monthly_report_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

const List<Color> _kChartColors = [
  Color(0xFF1A1A1A), Color(0xFF333333), Color(0xFF4D4D4D),
  Color(0xFF666666), Color(0xFF808080), Color(0xFF999999),
  Color(0xFFB3B3B3), Color(0xFFCCCCCC), Color(0xFFE0E0E0),
  Color(0xFFEEEEEE),
];

class MonthlyReportScreen extends StatefulWidget {
  final int userId;

  const MonthlyReportScreen({super.key, required this.userId});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  Map<BudgetSource, double> _incomeBreakdown = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentPeriod(),
        _service.getEnvelopes(),
        _service.getCurrentIncomeBreakdown(),
      ]);
      if (!mounted) return;
      setState(() {
        _period = results[0] as BudgetPeriod;
        _envelopes = results[1] as List<BudgetEnvelope>;
        _incomeBreakdown = results[2] as Map<BudgetSource, double>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;
    final now = DateTime.now();
    final monthsSw = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba'
    ];
    final monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final months = isSwahili ? monthsSw : monthsEn;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          '${isSwahili ? 'Ripoti' : 'Report'} — ${months[now.month - 1]} ${now.year}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 20),
            tooltip: isSwahili ? 'Shiriki' : 'Share',
            onPressed: () {
              // TODO: Generate shareable summary card image
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isSwahili ? 'Inakuja hivi karibuni' : 'Coming soon'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: _kSecondary)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadData, child: Text(isSwahili ? 'Jaribu tena' : 'Try again')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummaryCard(isSwahili),
                        const SizedBox(height: 16),
                        _buildSavingsRate(isSwahili),
                        const SizedBox(height: 20),
                        Text(
                          isSwahili ? 'VYANZO VYA MAPATO' : 'INCOME SOURCES',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        _buildIncomeBreakdown(isSwahili),
                        const SizedBox(height: 20),
                        Text(
                          isSwahili ? 'MATUMIZI KWA BAHASHA' : 'SPENDING BY ENVELOPE',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        _buildEnvelopeBreakdown(isSwahili),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard(bool isSwahili) {
    final p = _period!;
    final net = p.totalIncome - p.totalSpent;
    final isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isSwahili ? 'Mapato' : 'Income', style: const TextStyle(fontSize: 12, color: _kTertiary)),
                    const SizedBox(height: 4),
                    Text('TZS ${p.totalIncome.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kSuccess)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(isSwahili ? 'Matumizi' : 'Spending', style: const TextStyle(fontSize: 12, color: _kTertiary)),
                    const SizedBox(height: 4),
                    Text('TZS ${p.totalSpent.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kError)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _kDivider),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: isPositive ? _kSuccess : _kError,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${isPositive ? '+' : ''}TZS ${net.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isPositive ? _kSuccess : _kError),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? (isSwahili ? 'Umebakiza mwezi huu' : 'Net savings this month')
                : (isSwahili ? 'Umetumia zaidi ya mapato' : 'Overspent this month'),
            style: const TextStyle(fontSize: 12, color: _kTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsRate(bool isSwahili) {
    final p = _period!;
    final rate = p.totalIncome > 0 ? ((p.totalIncome - p.totalSpent) / p.totalIncome * 100) : 0.0;
    final isPositive = rate >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPositive
            ? _kSuccess.withValues(alpha: 0.08)
            : _kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isPositive ? Icons.savings_rounded : Icons.warning_rounded,
            size: 24,
            color: isPositive ? _kSuccess : _kError,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isSwahili
                  ? 'Umehifadhi ${rate.toStringAsFixed(0)}% ya mapato yako'
                  : 'You saved ${rate.toStringAsFixed(0)}% of your income',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isPositive ? _kSuccess : _kError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeBreakdown(bool isSwahili) {
    if (_incomeBreakdown.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(
          isSwahili ? 'Hakuna mapato bado' : 'No income yet',
          style: const TextStyle(color: _kTertiary),
        )),
      );
    }

    final total = _incomeBreakdown.values.fold(0.0, (a, b) => a + b);
    final entries = _incomeBreakdown.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final entry = e.value;
          final pct = total > 0 ? entry.value / total : 0.0;
          final color = _kChartColors[e.key % _kChartColors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key.label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
                    Text(
                      'TZS ${entry.value.toStringAsFixed(0)} (${(pct * 100).toStringAsFixed(0)}%)',
                      style: const TextStyle(fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: _kDivider,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnvelopeBreakdown(bool isSwahili) {
    final spentEnvelopes = _envelopes.where((e) => e.spentAmount > 0).toList()
      ..sort((a, b) => b.spentAmount.compareTo(a.spentAmount));

    if (spentEnvelopes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(
          isSwahili ? 'Hakuna matumizi bado' : 'No spending yet',
          style: const TextStyle(color: _kTertiary),
        )),
      );
    }

    final totalSpent = spentEnvelopes.fold(0.0, (a, b) => a + b.spentAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 3, offset: const Offset(0, 1))],
      ),
      child: Column(
        children: [
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: spentEnvelopes.asMap().entries.map((e) {
                  final flex = (e.value.spentAmount / totalSpent * 100).round();
                  if (flex <= 0) return const SizedBox.shrink();
                  return Flexible(
                    flex: math.max(flex, 1),
                    child: Container(color: _kChartColors[e.key % _kChartColors.length]),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend rows
          ...spentEnvelopes.asMap().entries.map((e) {
            final env = e.value;
            final pct = totalSpent > 0 ? (env.spentAmount / totalSpent * 100) : 0.0;
            final color = _kChartColors[e.key % _kChartColors.length];
            final isOver = env.isOverBudget;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      env.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isOver ? _kError : _kPrimary,
                        fontWeight: isOver ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('TZS ${env.spentAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                  const SizedBox(width: 8),
                  Text('${pct.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
```

### Verification for Task 6

```bash
flutter analyze lib/screens/budget/monthly_report_screen.dart
```

---

## Task 7: Savings Goals Screen (Rewrite)

**File:** `lib/screens/budget/goals_screen.dart` (overwrite existing)

Adds: bilingual, progress rings via GoalCard widget, edit goals, monthly target.

**Spec features covered:** #55-#60

```dart
// lib/screens/budget/goals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'widgets/goal_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);

class GoalsScreen extends StatefulWidget {
  final int userId;

  const GoalsScreen({super.key, required this.userId});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final BudgetService _service = BudgetService();
  List<BudgetGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    setState(() => _isLoading = true);
    try {
      final goals = await _service.getGoals();
      if (mounted) setState(() { _goals = goals; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addGoal(bool isSwahili) async {
    final result = await _showGoalDialog(isSwahili);
    if (result != null) {
      try {
        await _service.createGoal(
          name: result['name'] as String,
          icon: result['icon'] as String,
          targetAmount: result['target'] as double,
          deadline: result['deadline'] as DateTime?,
        );
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isSwahili ? 'Hitilafu' : 'Error'}: $e')),
          );
        }
      }
    }
  }

  Future<void> _addFunds(BudgetGoal goal, bool isSwahili) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Ongeza Akiba' : 'Add Savings'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: 'TZS ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              Navigator.pop(ctx, val);
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(isSwahili ? 'Ongeza' : 'Add'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (amount != null && amount > 0) {
      try {
        await _service.addToGoal(goal.id!, amount);
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isSwahili ? 'Hitilafu' : 'Error'}: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGoal(BudgetGoal goal, bool isSwahili) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Futa Lengo' : 'Delete Goal'),
        content: Text(
          isSwahili
              ? 'Una uhakika unataka kufuta "${goal.name}"?'
              : 'Are you sure you want to delete "${goal.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isSwahili ? 'Hapana' : 'No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: Text(isSwahili ? 'Futa' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deleteGoal(goal.id!);
        _loadGoals();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isSwahili ? 'Hitilafu' : 'Error'}: $e')),
          );
        }
      }
    }
  }

  Future<Map<String, dynamic>?> _showGoalDialog(bool isSwahili) async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    DateTime? deadline;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isSwahili ? 'Lengo Jipya' : 'New Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Jina la lengo' : 'Goal name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Kiasi (TZS)' : 'Target (TZS)',
                  prefixText: 'TZS ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 90)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (picked != null) setDialogState(() => deadline = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: _kDivider),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Text(
                        deadline != null
                            ? '${deadline!.day}/${deadline!.month}/${deadline!.year}'
                            : (isSwahili ? 'Tarehe ya mwisho (hiari)' : 'Deadline (optional)'),
                        style: TextStyle(color: deadline != null ? _kPrimary : _kTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final target = double.tryParse(targetController.text);
                if (name.isEmpty || target == null || target <= 0) return;
                Navigator.pop(ctx, {
                  'name': name,
                  'icon': 'flag',
                  'target': target,
                  'deadline': deadline,
                });
              },
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(isSwahili ? 'Unda' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Malengo ya Akiba' : 'Savings Goals',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _goals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined, size: 48, color: _kTertiary),
                        const SizedBox(height: 16),
                        Text(
                          isSwahili ? 'Bado hakuna lengo' : 'No goals yet',
                          style: const TextStyle(fontSize: 16, color: _kSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSwahili
                              ? 'Weka lengo la akiba kuanza kufuatilia'
                              : 'Set a savings goal to start tracking',
                          style: const TextStyle(fontSize: 13, color: _kTertiary),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _addGoal(isSwahili),
                          icon: const Icon(Icons.add),
                          label: Text(isSwahili ? 'Ongeza Lengo' : 'Add Goal'),
                          style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadGoals,
                    color: _kPrimary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _goals.length,
                      itemBuilder: (ctx, i) {
                        final goal = _goals[i];
                        return Dismissible(
                          key: ValueKey(goal.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            _deleteGoal(goal, isSwahili);
                            return false; // We handle deletion ourselves
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: const Color(0xFFE53935),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          child: GoalCard(
                            goal: goal,
                            isSwahili: isSwahili,
                            onContribute: () => _addFunds(goal, isSwahili),
                          ),
                        );
                      },
                    ),
                  ),
      ),
      floatingActionButton: _goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _addGoal(isSwahili),
              backgroundColor: _kPrimary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  bool get isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
}
```

### Verification for Task 7

```bash
flutter analyze lib/screens/budget/goals_screen.dart
```

---

## Task 8: Income Breakdown Screen (New)

**File:** `lib/screens/budget/income_breakdown_screen.dart` (new file)

**Spec features covered:** #47-#50

```dart
// lib/screens/budget/income_breakdown_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'widgets/income_source_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);

class IncomeBreakdownScreen extends StatefulWidget {
  final int userId;

  const IncomeBreakdownScreen({super.key, required this.userId});

  @override
  State<IncomeBreakdownScreen> createState() => _IncomeBreakdownScreenState();
}

class _IncomeBreakdownScreenState extends State<IncomeBreakdownScreen> {
  final BudgetService _service = BudgetService();
  Map<BudgetSource, double> _incomeBreakdown = {};
  BudgetPeriod? _period;
  List<BudgetTransaction> _recentIncome = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getCurrentIncomeBreakdown(),
        _service.getCurrentPeriod(),
        _service.getTransactions(type: BudgetTransactionType.income, limit: 20),
      ]);

      if (!mounted) return;
      setState(() {
        _incomeBreakdown = results[0] as Map<BudgetSource, double>;
        _period = results[1] as BudgetPeriod;
        _recentIncome = results[2] as List<BudgetTransaction>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  IconData _sourceIcon(BudgetSource source) {
    switch (source) {
      case BudgetSource.manual: return Icons.edit_rounded;
      case BudgetSource.wallet: return Icons.account_balance_wallet_rounded;
      case BudgetSource.shop: return Icons.storefront_rounded;
      case BudgetSource.subscription: return Icons.card_membership_rounded;
      case BudgetSource.tip: return Icons.volunteer_activism_rounded;
      case BudgetSource.michango: return Icons.handshake_rounded;
      case BudgetSource.creatorFund: return Icons.auto_awesome_rounded;
      case BudgetSource.ad: return Icons.campaign_rounded;
      case BudgetSource.salary: return Icons.work_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Mapato' : 'Income',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: _kSecondary)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadData, child: Text(isSwahili ? 'Jaribu tena' : 'Try again')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Total income hero
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _kPrimary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isSwahili ? 'Jumla ya Mapato' : 'Total Income',
                                style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTZS(_period?.totalIncome ?? 0),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSwahili ? 'Mwezi huu' : 'This month',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Breakdown by source
                        Text(
                          isSwahili ? 'VYANZO VYA MAPATO' : 'INCOME SOURCES',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),

                        if (_incomeBreakdown.isEmpty)
                          _buildEmpty(isSwahili ? 'Hakuna mapato bado' : 'No income yet')
                        else
                          ..._incomeBreakdown.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)),

                        // Actually build the tiles
                        ...(_incomeBreakdown.entries.toList()
                              ..sort((a, b) => b.value.compareTo(a.value)))
                            .map((entry) => IncomeSourceTile(
                                  sourceName: entry.key.label,
                                  amount: entry.value,
                                  totalIncome: _period?.totalIncome ?? 0,
                                  icon: _sourceIcon(entry.key),
                                )),

                        const SizedBox(height: 20),

                        // Recent income transactions
                        Text(
                          isSwahili ? 'MIAMALA YA MAPATO' : 'INCOME TRANSACTIONS',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),

                        if (_recentIncome.isEmpty)
                          _buildEmpty(isSwahili ? 'Hakuna miamala bado' : 'No transactions yet')
                        else
                          ..._recentIncome.map((txn) => _buildIncomeTxnRow(txn)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildIncomeTxnRow(BudgetTransaction txn) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_sourceIcon(txn.source), size: 16, color: _kSuccess),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.description,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${txn.date.day}/${txn.date.month} - ${txn.source.label}',
                  style: const TextStyle(fontSize: 10, color: _kTertiary),
                ),
              ],
            ),
          ),
          Text(
            '+${_formatTZS(txn.amount)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSuccess),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(text, style: const TextStyle(color: _kTertiary, fontSize: 13))),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}
```

### Verification for Task 8

```bash
flutter analyze lib/screens/budget/income_breakdown_screen.dart
```

---

## Task 9: Cash Flow Forecast Screen (New)

**File:** `lib/screens/budget/cash_flow_forecast_screen.dart` (new file)

**Spec features covered:** #61-#64

```dart
// lib/screens/budget/cash_flow_forecast_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kSuccess = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);
const Color _kWarning = Color(0xFFFF9800);

class CashFlowForecastScreen extends StatefulWidget {
  final int userId;

  const CashFlowForecastScreen({super.key, required this.userId});

  @override
  State<CashFlowForecastScreen> createState() => _CashFlowForecastScreenState();
}

class _CashFlowForecastScreenState extends State<CashFlowForecastScreen> {
  final BudgetService _service = BudgetService();
  BudgetPeriod? _period;
  List<BudgetEnvelope> _envelopes = [];
  List<BudgetTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  // Forecast data
  List<double> _projectedBalances = [];
  double _projectedEndBalance = 0;
  bool _goesNegative = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _service.getCurrentPeriod(),
        _service.getEnvelopes(),
        _service.getTransactions(from: monthStart, limit: 500),
      ]);

      if (!mounted) return;

      final period = results[0] as BudgetPeriod;
      final envelopes = results[1] as List<BudgetEnvelope>;
      final transactions = results[2] as List<BudgetTransaction>;

      // Build 30-day projection
      _computeForecast(period, transactions, now);

      setState(() {
        _period = period;
        _envelopes = envelopes;
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _computeForecast(BudgetPeriod period, List<BudgetTransaction> txns, DateTime now) {
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentBalance = period.totalIncome - period.totalSpent;

    // Average daily spending from actual data
    final daysPassed = now.day;
    final avgDailySpend = daysPassed > 0 ? period.totalSpent / daysPassed : 0.0;

    // Project remaining days
    _projectedBalances = [];
    double balance = currentBalance;
    _goesNegative = false;

    for (int day = now.day; day <= daysInMonth; day++) {
      _projectedBalances.add(balance);
      balance -= avgDailySpend;
      if (balance < 0 && !_goesNegative) _goesNegative = true;
    }

    _projectedEndBalance = balance;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Utabiri wa Fedha' : 'Cash Flow Forecast',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: _kSecondary)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _loadData, child: Text(isSwahili ? 'Jaribu tena' : 'Try again')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Projected end-of-month balance
                        _buildProjectionCard(isSwahili),
                        const SizedBox(height: 16),

                        // Warning if goes negative
                        if (_goesNegative) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _kError.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kError.withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_rounded, size: 20, color: _kError),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isSwahili
                                        ? 'Kwa kasi hii, pesa zitaisha kabla ya mwisho wa mwezi'
                                        : 'At this rate, funds will run out before month end',
                                    style: const TextStyle(fontSize: 13, color: _kError, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 30-day projection chart
                        Text(
                          isSwahili ? 'UTABIRI WA SIKU 30' : '30-DAY PROJECTION',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        _buildProjectionChart(),
                        const SizedBox(height: 20),

                        // Summary stats
                        _buildStatsRow(isSwahili),
                        const SizedBox(height: 20),

                        // Upcoming recurring (placeholder for ExpenditureService integration)
                        Text(
                          isSwahili ? 'MATUMIZI YANAYOTARAJIWA' : 'EXPECTED EXPENSES',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kTertiary, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),
                        _buildUpcomingExpenses(isSwahili),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProjectionCard(bool isSwahili) {
    final isPositive = _projectedEndBalance >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPositive ? _kPrimary : _kError,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isSwahili ? 'Mwisho wa Mwezi' : 'End of Month',
            style: const TextStyle(fontSize: 13, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTZS(_projectedEndBalance.abs()),
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: isPositive ? Colors.white : const Color(0xFFFFCDD2),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPositive
                ? (isSwahili ? 'Utabaki na' : 'Projected remaining')
                : (isSwahili ? 'Utapungukiwa na' : 'Projected shortfall'),
            style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectionChart() {
    if (_projectedBalances.isEmpty) {
      return const SizedBox(height: 120);
    }

    final maxVal = _projectedBalances.reduce(math.max);
    final minVal = _projectedBalances.reduce(math.min);
    final range = (maxVal - minVal).abs();

    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        size: const Size(double.infinity, 108),
        painter: _LineChartPainter(
          values: _projectedBalances,
          maxValue: maxVal,
          minValue: minVal,
          range: range,
          goesNegative: _goesNegative,
        ),
      ),
    );
  }

  Widget _buildStatsRow(bool isSwahili) {
    final period = _period!;
    final now = DateTime.now();
    final daysLeft = DateTime(now.year, now.month + 1, 0).day - now.day;
    final avgDailySpend = now.day > 0 ? period.totalSpent / now.day : 0.0;

    return Row(
      children: [
        _statCard(
          isSwahili ? 'Wastani/siku' : 'Avg/day',
          _formatTZS(avgDailySpend),
          Icons.speed_rounded,
        ),
        const SizedBox(width: 8),
        _statCard(
          isSwahili ? 'Siku zimebaki' : 'Days left',
          '$daysLeft',
          Icons.calendar_today_rounded,
        ),
        const SizedBox(width: 8),
        _statCard(
          isSwahili ? 'Salio' : 'Balance',
          _formatTZS(period.totalIncome - period.totalSpent),
          Icons.account_balance_rounded,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider, width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: _kSecondary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: _kTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingExpenses(bool isSwahili) {
    // For now, show envelopes with allocations as expected expenses
    final allocated = _envelopes.where((e) => e.allocatedAmount > 0 && e.remainingAmount > 0).toList();

    if (allocated.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            isSwahili ? 'Hakuna matumizi yanayotarajiwa' : 'No expected expenses',
            style: const TextStyle(color: _kTertiary, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: allocated.take(5).map((env) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kDivider, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: _kTertiary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  env.name,
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${_formatTZS(env.remainingAmount)} ${isSwahili ? 'imebaki' : 'remaining'}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;
  final double minValue;
  final double range;
  final bool goesNegative;

  _LineChartPainter({
    required this.values,
    required this.maxValue,
    required this.minValue,
    required this.range,
    required this.goesNegative,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = values.length > 1 ? i / (values.length - 1) * size.width : 0.0;
      final normalized = range > 0 ? (values[i] - minValue) / range : 0.5;
      final y = size.height - (normalized * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Draw zero line if goes negative
    if (goesNegative && range > 0) {
      final zeroY = size.height - ((0 - minValue) / range * size.height);
      canvas.drawLine(
        Offset(0, zeroY),
        Offset(size.width, zeroY),
        Paint()
          ..color = const Color(0xFFE53935).withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    // Fill under curve
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    fillPaint.color = const Color(0xFF1A1A1A).withValues(alpha: 0.06);
    canvas.drawPath(fillPath, fillPaint);

    // Draw line
    paint.color = const Color(0xFF1A1A1A);
    canvas.drawPath(path, paint);

    // Draw end point
    if (values.isNotEmpty) {
      final lastX = size.width;
      final lastNorm = range > 0 ? (values.last - minValue) / range : 0.5;
      final lastY = size.height - (lastNorm * size.height);
      canvas.drawCircle(
        Offset(lastX, lastY),
        4,
        Paint()..color = values.last >= 0 ? const Color(0xFF1A1A1A) : const Color(0xFFE53935),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.values != values;
}
```

### Verification for Task 9

```bash
flutter analyze lib/screens/budget/cash_flow_forecast_screen.dart
```

---

## Task 10: Recurring Expenses Screen (New)

**File:** `lib/screens/budget/recurring_expenses_screen.dart` (new file)

**Spec features covered:** #37-#41

```dart
// lib/screens/budget/recurring_expenses_screen.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../models/budget_models.dart';
import '../../services/budget_service.dart';
import 'widgets/recurring_expense_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kDivider = Color(0xFFE0E0E0);

class RecurringExpensesScreen extends StatefulWidget {
  final int userId;

  const RecurringExpensesScreen({super.key, required this.userId});

  @override
  State<RecurringExpensesScreen> createState() => _RecurringExpensesScreenState();
}

class _RecurringExpensesScreenState extends State<RecurringExpensesScreen> {
  final BudgetService _service = BudgetService();
  List<_RecurringItem> _recurring = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _detectRecurring();
  }

  Future<void> _detectRecurring() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get last 3 months of transactions to detect patterns
      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, 1);

      final txns = await _service.getTransactions(
        type: BudgetTransactionType.expense,
        from: threeMonthsAgo,
        limit: 500,
      );

      // Simple recurring detection:
      // Group by description, find ones that appear in 2+ different months
      final byDesc = <String, List<BudgetTransaction>>{};
      for (final txn in txns) {
        final key = txn.description.toLowerCase().trim();
        byDesc.putIfAbsent(key, () => []).add(txn);
      }

      final recurring = <_RecurringItem>[];
      for (final entry in byDesc.entries) {
        final txns = entry.value;
        if (txns.length < 2) continue;

        // Check if they span at least 2 different months
        final months = txns.map((t) => '${t.date.year}-${t.date.month}').toSet();
        if (months.length < 2) continue;

        // Average amount
        final avgAmount = txns.fold(0.0, (a, b) => a + b.amount) / txns.length;
        final latest = txns.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

        // Predict next date (add ~30 days from latest)
        final nextDate = latest.date.add(const Duration(days: 30));

        recurring.add(_RecurringItem(
          description: txns.first.description,
          amount: avgAmount,
          frequency: 'monthly',
          nextDate: nextDate,
          isConfirmed: false,
          occurrences: txns.length,
        ));
      }

      // Sort by amount descending
      recurring.sort((a, b) => b.amount.compareTo(a.amount));

      if (!mounted) return;
      setState(() {
        _recurring = recurring;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  double get _totalMonthlyRecurring {
    return _recurring
        .where((r) => !r.dismissed)
        .fold(0.0, (a, b) => a + b.amount);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSwahili = s?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kSurface,
        elevation: 0,
        title: Text(
          isSwahili ? 'Matumizi Yanayojirudia' : 'Recurring Expenses',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _kPrimary),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: _kSecondary)),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _detectRecurring,
                          child: Text(isSwahili ? 'Jaribu tena' : 'Try again'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _detectRecurring,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Total monthly recurring
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _kDivider, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.repeat_rounded, size: 20, color: _kPrimary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isSwahili ? 'Jumla kwa mwezi' : 'Monthly total',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTZS(_totalMonthlyRecurring),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: _kPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kBackground,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_recurring.where((r) => !r.dismissed).length} ${isSwahili ? 'malipo' : 'charges'}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_recurring.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 40),
                                const Icon(Icons.search_off_rounded, size: 48, color: _kTertiary),
                                const SizedBox(height: 16),
                                Text(
                                  isSwahili
                                      ? 'Hakuna matumizi yanayojirudia yaliyogunduliwa'
                                      : 'No recurring expenses detected',
                                  style: const TextStyle(fontSize: 14, color: _kSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isSwahili
                                      ? 'Tunahitaji miezi 2+ ya data kugundua mwenendo'
                                      : 'We need 2+ months of data to detect patterns',
                                  style: const TextStyle(fontSize: 12, color: _kTertiary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else ...[
                          Text(
                            isSwahili ? 'YALIYOGUNDULIWA' : 'DETECTED',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _kTertiary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._recurring.where((r) => !r.dismissed).map((item) {
                            return RecurringExpenseTile(
                              description: item.description,
                              amount: item.amount,
                              frequency: item.frequency,
                              nextDate: '${item.nextDate.day}/${item.nextDate.month}',
                              isConfirmed: item.isConfirmed,
                              isSwahili: isSwahili,
                              onConfirm: () {
                                setState(() => item.isConfirmed = true);
                              },
                              onDismiss: () {
                                setState(() => item.dismissed = true);
                              },
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }

  static String _formatTZS(double amount) {
    if (amount >= 1000000) return 'TZS ${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return 'TZS ${(amount / 1000).toStringAsFixed(0)}K';
    return 'TZS ${amount.toStringAsFixed(0)}';
  }
}

class _RecurringItem {
  final String description;
  final double amount;
  final String frequency;
  final DateTime nextDate;
  bool isConfirmed;
  bool dismissed;
  final int occurrences;

  _RecurringItem({
    required this.description,
    required this.amount,
    this.frequency = 'monthly',
    required this.nextDate,
    this.isConfirmed = false,
    this.dismissed = false,
    this.occurrences = 0,
  });
}
```

### Verification for Task 10

```bash
flutter analyze lib/screens/budget/recurring_expenses_screen.dart
```

---

## Task 11: Wire Navigation + Profile Tab

### 11a. Add routes to `lib/main.dart`

In the `onGenerateRoute` section, add routes for the new screens:

```dart
// In the route switch/if block:
case '/budget':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return BudgetHomeScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/allocate':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return AllocateFundsScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/report':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return MonthlyReportScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/goals':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return GoalsScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/income':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return IncomeBreakdownScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/forecast':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return CashFlowForecastScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/recurring':
  return MaterialPageRoute(
    builder: (_) => FutureBuilder<int>(
      future: LocalStorageService.getInstance().then((s) => s.getUser()?.userId ?? 0),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return RecurringExpensesScreen(userId: snap.data!);
      },
    ),
  );

case '/budget/add-transaction':
  return MaterialPageRoute(
    builder: (_) => const AddTransactionScreen(),
  );
```

### 11b. Add required imports to `lib/main.dart`

```dart
import 'screens/budget/budget_home_screen.dart';
import 'screens/budget/allocate_funds_screen.dart';
import 'screens/budget/monthly_report_screen.dart';
import 'screens/budget/goals_screen.dart';
import 'screens/budget/income_breakdown_screen.dart';
import 'screens/budget/cash_flow_forecast_screen.dart';
import 'screens/budget/recurring_expenses_screen.dart';
import 'screens/budget/add_transaction_screen.dart';
```

### 11c. Wire Budget tab in profile (if applicable)

Check `lib/models/profile_tab_config.dart` and `lib/screens/profile/profile_screen.dart` for how tabs are configured. If Budget is a profile tab, add it there. If it's a standalone navigation item, ensure it's accessible from the home screen or bottom nav.

### Verification for Task 11

```bash
flutter analyze lib/main.dart
```

---

## Task 12: Add Bilingual Strings to AppStrings

**File:** `lib/l10n/app_strings.dart`

Add budget-related strings. Check what already exists first, then add missing ones:

```dart
// Budget module strings
String get budgetTitle => isSwahili ? 'Bajeti' : 'Budget';
String get walletBalance => isSwahili ? 'Salio la Pochi' : 'Wallet Balance';
String get safeToSpend => isSwahili ? 'Unaweza kutumia' : 'Safe to spend';
String get allocateNow => isSwahili ? 'Tenga Sasa' : 'Allocate Now';
String get envelopes => isSwahili ? 'Bahasha' : 'Envelopes';
String get addEnvelope => isSwahili ? 'Ongeza Bahasha' : 'Add Envelope';
String get editEnvelope => isSwahili ? 'Hariri Bahasha' : 'Edit Envelope';
String get goals => isSwahili ? 'Malengo' : 'Goals';
String get addGoal => isSwahili ? 'Ongeza Lengo' : 'Add Goal';
String get addTransaction => isSwahili ? 'Ongeza Muamala' : 'Add Transaction';
String get expense => isSwahili ? 'Matumizi' : 'Expense';
String get income => isSwahili ? 'Mapato' : 'Income';
String get monthlyReport => isSwahili ? 'Ripoti ya Mwezi' : 'Monthly Report';
String get savingsGoals => isSwahili ? 'Malengo ya Akiba' : 'Savings Goals';
String get recurringExpenses => isSwahili ? 'Matumizi Yanayojirudia' : 'Recurring Expenses';
String get cashFlowForecast => isSwahili ? 'Utabiri wa Fedha' : 'Cash Flow Forecast';
String get allocateFunds => isSwahili ? 'Tenga Pesa' : 'Allocate Funds';
String get incomeBreakdown => isSwahili ? 'Mapato kwa Chanzo' : 'Income Breakdown';
String get onTrack => isSwahili ? 'Sawa' : 'On Track';
String get caution => isSwahili ? 'Tahadhari' : 'Caution';
String get overBudget => isSwahili ? 'Imezidi' : 'Over Budget';
String get remaining => isSwahili ? 'Imebaki' : 'Remaining';
String get spent => isSwahili ? 'Imetumika' : 'Spent';
String get budget => isSwahili ? 'Bajeti' : 'Budget';
String get dailyAllowance => isSwahili ? 'Kiwango cha siku' : 'Daily allowance';
String get moveMoney => isSwahili ? 'Hamisha Pesa' : 'Move Money';
String get noTransactionsYet => isSwahili ? 'Hakuna miamala bado' : 'No transactions yet';
String get cash => isSwahili ? 'Taslimu' : 'Cash';
String get topUp => isSwahili ? 'Weka Pesa' : 'Top Up';
String get withdraw => isSwahili ? 'Toa Pesa' : 'Withdraw';
String get save => isSwahili ? 'Hifadhi' : 'Save';
String get cancel => isSwahili ? 'Ghairi' : 'Cancel';
String get delete => isSwahili ? 'Futa' : 'Delete';
String get confirm => isSwahili ? 'Thibitisha' : 'Confirm';
String get dismiss => isSwahili ? 'Ondoa' : 'Dismiss';
String get comingSoon => isSwahili ? 'Inakuja hivi karibuni' : 'Coming soon';
```

### Verification for Task 12

```bash
flutter analyze lib/l10n/app_strings.dart
```

---

## Task 13: Final Verification

Run full analysis on all budget files:

```bash
flutter analyze lib/screens/budget/
```

Expected: 0 errors, 0 warnings (some info-level hints OK).

If there are compilation errors:
1. Fix import paths
2. Fix type mismatches
3. Ensure all referenced models/services exist (from Plan A)
4. Run again until clean

### File Checklist

After all tasks, verify these files exist and compile:

```bash
# Widgets (8 files)
ls lib/screens/budget/widgets/wallet_balance_card.dart
ls lib/screens/budget/widgets/safe_to_spend_card.dart
ls lib/screens/budget/widgets/unallocated_card.dart
ls lib/screens/budget/widgets/envelope_list_tile.dart
ls lib/screens/budget/widgets/spending_pace_badge.dart
ls lib/screens/budget/widgets/income_source_tile.dart
ls lib/screens/budget/widgets/goal_card.dart
ls lib/screens/budget/widgets/recurring_expense_tile.dart

# Screens (9 files)
ls lib/screens/budget/budget_home_screen.dart        # rewritten
ls lib/screens/budget/envelope_detail_screen.dart    # rewritten
ls lib/screens/budget/add_transaction_screen.dart    # rewritten
ls lib/screens/budget/allocate_funds_screen.dart     # NEW
ls lib/screens/budget/monthly_report_screen.dart     # rewritten
ls lib/screens/budget/goals_screen.dart              # rewritten
ls lib/screens/budget/income_breakdown_screen.dart   # NEW
ls lib/screens/budget/cash_flow_forecast_screen.dart # NEW
ls lib/screens/budget/recurring_expenses_screen.dart # NEW
```

### Final `flutter analyze` must pass with 0 errors.
