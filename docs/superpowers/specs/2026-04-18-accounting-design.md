# Accounting Module Design
_Date: 2026-04-18_

## Overview

A new `biz_accounting` tab under the Business category in the profile screen. Full double-entry accounting module backed by the existing `/api/accounting/*` backend endpoints. Located at `lib/accounting/`.

---

## Architecture

```
lib/accounting/
├── accounting_module.dart              # Entry point — TabBar with 3 tabs
├── models/
│   └── accounting_models.dart         # All data models
├── services/
│   └── accounting_service.dart        # Static methods for all 6 endpoints
└── pages/
    ├── accounting_overview_page.dart   # Tab 1: Book summary + key metrics
    ├── accounting_journal_page.dart    # Tab 2: Paginated ledger + entry detail
    └── accounting_reports_page.dart    # Tab 3: Trial Balance / P&L / Balance Sheet
```

The `accounting_module.dart` is registered as case `biz_accounting` in `profile_screen.dart`. It receives `userId` (int) — no `businessId`, the backend uses `user_id` directly.

---

## Backend Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/accounting/book-summary` | Overview metrics |
| GET | `/api/accounting/journal-ledger` | Paginated journal entries |
| GET | `/api/accounting/journal-entry/{id}` | Single entry detail |
| GET | `/api/accounting/trial-balance` | Trial balance lines |
| GET | `/api/accounting/profit-and-loss` | Income/expense/net profit |
| GET | `/api/accounting/balance-sheet` | Assets/liabilities/equity |

All endpoints accept `user_id` (int, nullable) and optional `book=platform`. Date endpoints accept `date_from` / `date_to`. Journal ledger also accepts `source_type` and `per_page` (1–100).

---

## Data Models (`accounting_models.dart`)

All models use `factory fromJson(Map<String, dynamic> json)` with null-safe `_parseInt`, `_parseDouble`, `_parseBool` helpers.

```dart
class BookSummary {
  final int entryCount;
  final double totalDebit, totalCredit;
  final bool balanced;
  final List<UnbalancedEntry> unbalancedEntries;
}

class UnbalancedEntry {
  final int entryId;
  final String entryNumber;
  final double debit, credit, difference;
}

class JournalEntry {
  final int id;
  final String entryNumber, description, sourceType;
  final int? sourceId;
  final DateTime postedAt;
  final List<JournalLine> lines;
  final JournalTotals totals;
}

class JournalLine {
  final String coaCode, accountName;
  final double debit, credit;
}

class JournalTotals {
  final double debit, credit;
  final bool balanced;
}

class TrialBalance {
  final String? dateFrom, dateTo;
  final List<TrialBalanceLine> lines;
}

class TrialBalanceLine {
  final String coaCode, accountName;
  final double debit, credit;
}

class ProfitAndLoss {
  final String dateFrom, dateTo;
  final List<PnlAccount> incomeAccounts, expenseAccounts;
  final double netProfit;
}

class PnlAccount {
  final String coaCode, accountName;
  final double amount;
}

class BalanceSheet {
  final List<BsAccount> assets, liabilities, equity;
}

class BsAccount {
  final String coaCode, accountName;
  final double amount;
}
```

---

## Service Layer (`accounting_service.dart`)

Static-method class (no instantiation), auth token passed as parameter — matches existing service conventions.

```dart
class AccountingService {
  static Future<BookSummary?> getBookSummary({required String token, required int userId, String? dateFrom, String? dateTo});
  static Future<List<JournalEntry>> getJournalLedger({required String token, required int userId, String? dateFrom, String? dateTo, String? sourceType, int perPage = 20});
  static Future<JournalEntry?> getJournalEntry({required String token, required int entryId});
  static Future<TrialBalance?> getTrialBalance({required String token, required int userId, String? dateFrom, String? dateTo});
  static Future<ProfitAndLoss?> getProfitAndLoss({required String token, required int userId, required String dateFrom, required String dateTo});
  static Future<BalanceSheet?> getBalanceSheet({required String token, required int userId});
}
```

---

## UI Design

### accounting_module.dart
- `DefaultTabController` with 3 tabs
- Tab labels: Overview / Journal / Reports (bilingual)
- Passes `userId` and auth `token` to each page

### Tab 1 — Overview (`accounting_overview_page.dart`)
- Date range filter row at top (date_from, date_to)
- Summary cards row: Entry Count, Total Debits, Total Credits, Balanced (green ✓ / red ✗)
- If `!balanced`: red warning section listing unbalanced entries (entry number, difference)
- Pull-to-refresh

### Tab 2 — Journal (`accounting_journal_page.dart`)
- Filter bar: date range pickers + source_type dropdown
- Paginated `ListView` of `JournalEntry` cards:
  - Entry number + source type chip
  - Description
  - Posted date
  - Debit / Credit totals
- Tap → `showModalBottomSheet` with full lines table (COA code, account name, debit, credit columns)
- "Load more" button at bottom (per_page=20)

### Tab 3 — Reports (`accounting_reports_page.dart`)
- `SegmentedButton` to switch: Trial Balance | P&L | Balance Sheet
- **Trial Balance:** date range picker + two-column table (Debit / Credit) per account line, totals row
- **P&L:** date range pickers (required) + Income section, Expenses section, Net Profit footer card
- **Balance Sheet:** three expandable `ExpansionTile` sections: Assets, Liabilities, Equity

### Design conventions
- Palette: `#1A1A1A` dark, `#FAFAFA` background, `#FFFFFF` card — matches TaxPage/PayrollPage
- All dynamic text: `maxLines` + `TextOverflow.ellipsis`
- `SafeArea` wrapping all pages
- Bilingual labels via `AppStringsScope.of(context)?.isSwahili`
- `try/catch` + `mounted` guard on all async calls

---

## Profile Screen Integration

In `lib/screens/profile/profile_screen.dart`, add:

```dart
case 'biz_accounting':
  return AccountingModule(userId: userId);
```

After the `biz_appointments` case (line ~2294). Also add the import for `accounting_module.dart`.

---

## Out of Scope

- Manual journal entry creation (read-only view of backend-generated entries)
- Chart of accounts management UI
- Export to PDF/CSV
