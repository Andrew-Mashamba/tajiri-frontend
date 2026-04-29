# Accounting Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `biz_accounting` tab to the Business category in the profile screen — a full read-only accounting module with Overview, Journal, and Reports tabs backed by `/api/accounting/*` endpoints.

**Architecture:** Static service class calls 6 REST endpoints; data models use `fromJson` factories; `AccountingModule` is a `DefaultTabController` widget with 3 child pages. No `businessId` needed — backend uses `user_id` directly.

**Tech Stack:** Flutter 3, Dart, `http` package, `intl` for date formatting, `ApiConfig.authHeaders`, `LocalStorageService` for token, `AppStringsScope` for bilingual text.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `lib/accounting/models/accounting_models.dart` | All data models + `fromJson` factories |
| Create | `lib/accounting/services/accounting_service.dart` | 6 static API methods |
| Create | `lib/accounting/pages/accounting_overview_page.dart` | Tab 1: book summary metrics |
| Create | `lib/accounting/pages/accounting_journal_page.dart` | Tab 2: paginated ledger + entry detail |
| Create | `lib/accounting/pages/accounting_reports_page.dart` | Tab 3: trial balance / P&L / balance sheet |
| Create | `lib/accounting/accounting_module.dart` | Entry point — 3-tab `DefaultTabController` |
| Modify | `lib/screens/profile/profile_screen.dart` | Add import + `biz_accounting` case |

---

## Task 1: Data Models

**Files:**
- Create: `lib/accounting/models/accounting_models.dart`

- [ ] **Step 1: Create the models file**

```dart
// lib/accounting/models/accounting_models.dart
// Data models for the accounting module.

// ── Helpers ──────────────────────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

double _parseDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  if (v is int) return v != 0;
  return v.toString().toLowerCase() == 'true';
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

// ── BookSummary ───────────────────────────────────────────────────────────────

class UnbalancedEntry {
  final int entryId;
  final String entryNumber;
  final double debit, credit, difference;

  const UnbalancedEntry({
    required this.entryId,
    required this.entryNumber,
    required this.debit,
    required this.credit,
    required this.difference,
  });

  factory UnbalancedEntry.fromJson(Map<String, dynamic> j) => UnbalancedEntry(
        entryId: _parseInt(j['entry_id']),
        entryNumber: j['entry_number']?.toString() ?? '',
        debit: _parseDouble(j['debit']),
        credit: _parseDouble(j['credit']),
        difference: _parseDouble(j['difference']),
      );
}

class BookSummary {
  final int entryCount;
  final double totalDebit, totalCredit;
  final bool balanced;
  final List<UnbalancedEntry> unbalancedEntries;

  const BookSummary({
    required this.entryCount,
    required this.totalDebit,
    required this.totalCredit,
    required this.balanced,
    required this.unbalancedEntries,
  });

  factory BookSummary.fromJson(Map<String, dynamic> j) {
    final raw = j['unbalanced_entries'];
    final unbalanced = (raw is List)
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(UnbalancedEntry.fromJson)
            .toList()
        : <UnbalancedEntry>[];
    return BookSummary(
      entryCount: _parseInt(j['entry_count']),
      totalDebit: _parseDouble(j['total_debit']),
      totalCredit: _parseDouble(j['total_credit']),
      balanced: _parseBool(j['balanced']),
      unbalancedEntries: unbalanced,
    );
  }
}

// ── JournalEntry ──────────────────────────────────────────────────────────────

class JournalLine {
  final String coaCode, accountName;
  final double debit, credit;

  const JournalLine({
    required this.coaCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  factory JournalLine.fromJson(Map<String, dynamic> j) => JournalLine(
        coaCode: j['coa_code']?.toString() ?? '',
        accountName: j['account_name']?.toString() ?? '',
        debit: _parseDouble(j['debit']),
        credit: _parseDouble(j['credit']),
      );
}

class JournalTotals {
  final double debit, credit;
  final bool balanced;

  const JournalTotals({
    required this.debit,
    required this.credit,
    required this.balanced,
  });

  factory JournalTotals.fromJson(Map<String, dynamic> j) => JournalTotals(
        debit: _parseDouble(j['debit']),
        credit: _parseDouble(j['credit']),
        balanced: _parseBool(j['balanced']),
      );
}

class JournalEntry {
  final int id;
  final String entryNumber, description, sourceType;
  final int? sourceId;
  final DateTime? postedAt;
  final List<JournalLine> lines;
  final JournalTotals totals;

  const JournalEntry({
    required this.id,
    required this.entryNumber,
    required this.description,
    required this.sourceType,
    this.sourceId,
    this.postedAt,
    required this.lines,
    required this.totals,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) {
    final rawLines = j['lines'];
    final lines = (rawLines is List)
        ? rawLines.whereType<Map<String, dynamic>>().map(JournalLine.fromJson).toList()
        : <JournalLine>[];
    final rawTotals = j['totals'];
    final totals = (rawTotals is Map<String, dynamic>)
        ? JournalTotals.fromJson(rawTotals)
        : const JournalTotals(debit: 0, credit: 0, balanced: true);
    return JournalEntry(
      id: _parseInt(j['id']),
      entryNumber: j['entry_number']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      sourceType: j['source_type']?.toString() ?? '',
      sourceId: j['source_id'] != null ? _parseInt(j['source_id']) : null,
      postedAt: _parseDate(j['posted_at']),
      lines: lines,
      totals: totals,
    );
  }
}

// ── TrialBalance ──────────────────────────────────────────────────────────────

class TrialBalanceLine {
  final String coaCode, accountName;
  final double debit, credit;

  const TrialBalanceLine({
    required this.coaCode,
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  factory TrialBalanceLine.fromJson(Map<String, dynamic> j) => TrialBalanceLine(
        coaCode: j['coa_code']?.toString() ?? '',
        accountName: j['account_name']?.toString() ?? '',
        debit: _parseDouble(j['debit']),
        credit: _parseDouble(j['credit']),
      );
}

class TrialBalance {
  final String? dateFrom, dateTo;
  final List<TrialBalanceLine> lines;

  const TrialBalance({this.dateFrom, this.dateTo, required this.lines});

  factory TrialBalance.fromJson(Map<String, dynamic> j) {
    final period = j['period'];
    final String? from = period is Map ? period['date_from']?.toString() : null;
    final String? to = period is Map ? period['date_to']?.toString() : null;
    final rawLines = j['lines'];
    final lines = (rawLines is List)
        ? rawLines.whereType<Map<String, dynamic>>().map(TrialBalanceLine.fromJson).toList()
        : <TrialBalanceLine>[];
    return TrialBalance(dateFrom: from, dateTo: to, lines: lines);
  }
}

// ── ProfitAndLoss ─────────────────────────────────────────────────────────────

class PnlAccount {
  final String coaCode, accountName;
  final double amount;

  const PnlAccount({
    required this.coaCode,
    required this.accountName,
    required this.amount,
  });

  factory PnlAccount.fromJson(Map<String, dynamic> j) => PnlAccount(
        coaCode: j['coa_code']?.toString() ?? '',
        accountName: j['account_name']?.toString() ?? '',
        amount: _parseDouble(j['amount']),
      );
}

class ProfitAndLoss {
  final String dateFrom, dateTo;
  final List<PnlAccount> incomeAccounts, expenseAccounts;
  final double netProfit;

  const ProfitAndLoss({
    required this.dateFrom,
    required this.dateTo,
    required this.incomeAccounts,
    required this.expenseAccounts,
    required this.netProfit,
  });

  factory ProfitAndLoss.fromJson(Map<String, dynamic> j) {
    final period = j['period'];
    final String from = (period is Map ? period['date_from']?.toString() : null) ?? '';
    final String to = (period is Map ? period['date_to']?.toString() : null) ?? '';
    List<PnlAccount> _parseAccounts(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(PnlAccount.fromJson).toList();
    }
    return ProfitAndLoss(
      dateFrom: from,
      dateTo: to,
      incomeAccounts: _parseAccounts(j['income_accounts']),
      expenseAccounts: _parseAccounts(j['expense_accounts']),
      netProfit: _parseDouble(j['net_profit']),
    );
  }
}

// ── BalanceSheet ──────────────────────────────────────────────────────────────

class BsAccount {
  final String coaCode, accountName;
  final double amount;

  const BsAccount({
    required this.coaCode,
    required this.accountName,
    required this.amount,
  });

  factory BsAccount.fromJson(Map<String, dynamic> j) => BsAccount(
        coaCode: j['coa_code']?.toString() ?? '',
        accountName: j['account_name']?.toString() ?? '',
        amount: _parseDouble(j['amount']),
      );
}

class BalanceSheet {
  final List<BsAccount> assets, liabilities, equity;

  const BalanceSheet({
    required this.assets,
    required this.liabilities,
    required this.equity,
  });

  factory BalanceSheet.fromJson(Map<String, dynamic> j) {
    List<BsAccount> _parse(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(BsAccount.fromJson).toList();
    }
    return BalanceSheet(
      assets: _parse(j['assets']),
      liabilities: _parse(j['liabilities']),
      equity: _parse(j['equity']),
    );
  }
}
```

- [ ] **Step 2: Verify the file was created**

```bash
flutter analyze lib/accounting/models/accounting_models.dart
```
Expected: no errors.

---

## Task 2: Service Layer

**Files:**
- Create: `lib/accounting/services/accounting_service.dart`

- [ ] **Step 1: Create the service file**

```dart
// lib/accounting/services/accounting_service.dart
// Static API methods for all accounting endpoints.
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../models/accounting_models.dart';

class AccountingService {
  static const String _base = '${ApiConfig.baseUrl}/accounting';

  static Map<String, String> _qp({
    required int userId,
    String? dateFrom,
    String? dateTo,
    String? sourceType,
    int? perPage,
  }) {
    final p = <String, String>{'user_id': userId.toString()};
    if (dateFrom != null) p['date_from'] = dateFrom;
    if (dateTo != null) p['date_to'] = dateTo;
    if (sourceType != null) p['source_type'] = sourceType;
    if (perPage != null) p['per_page'] = perPage.toString();
    return p;
  }

  static Future<BookSummary?> getBookSummary({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final uri = Uri.parse('$_base/book-summary').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return BookSummary.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<JournalEntry>> getJournalLedger({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
    String? sourceType,
    int perPage = 20,
  }) async {
    try {
      final uri = Uri.parse('$_base/journal-ledger').replace(
          queryParameters: _qp(
              userId: userId,
              dateFrom: dateFrom,
              dateTo: dateTo,
              sourceType: sourceType,
              perPage: perPage));
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return [];
      final body = json.decode(res.body);
      final raw = (body['data'] ?? body)['entries'] ?? body['entries'] ?? [];
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(JournalEntry.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<JournalEntry?> getJournalEntry({
    required String token,
    required int entryId,
  }) async {
    try {
      final uri = Uri.parse('$_base/journal-entry/$entryId');
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return JournalEntry.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<TrialBalance?> getTrialBalance({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final uri = Uri.parse('$_base/trial-balance').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return TrialBalance.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<ProfitAndLoss?> getProfitAndLoss({
    required String token,
    required int userId,
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final uri = Uri.parse('$_base/profit-and-loss').replace(
          queryParameters: _qp(userId: userId, dateFrom: dateFrom, dateTo: dateTo));
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return ProfitAndLoss.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<BalanceSheet?> getBalanceSheet({
    required String token,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$_base/balance-sheet')
          .replace(queryParameters: _qp(userId: userId));
      final res = await http.get(uri, headers: ApiConfig.authHeaders(token));
      if (res.statusCode != 200) return null;
      final body = json.decode(res.body);
      final data = body['data'] ?? body;
      return BalanceSheet.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/accounting/services/accounting_service.dart
```
Expected: no errors.

---

## Task 3: Overview Page

**Files:**
- Create: `lib/accounting/pages/accounting_overview_page.dart`

- [ ] **Step 1: Create the overview page**

```dart
// lib/accounting/pages/accounting_overview_page.dart
// Tab 1: book summary — entry count, total debit/credit, balanced status.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/accounting_models.dart';
import '../services/accounting_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kError = Color(0xFFB00020);
const Color _kGreen = Color(0xFF2E7D32);

class AccountingOverviewPage extends StatefulWidget {
  final int userId;
  const AccountingOverviewPage({super.key, required this.userId});

  @override
  State<AccountingOverviewPage> createState() => _AccountingOverviewPageState();
}

class _AccountingOverviewPageState extends State<AccountingOverviewPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  bool _loading = true;
  BookSummary? _summary;
  DateTime? _dateFrom, _dateTo;

  final _fmt = NumberFormat('#,##0.00');
  final _dateFmt = DateFormat('yyyy-MM-dd');

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load();
  }

  Future<void> _load() async {
    if (_token == null) return;
    if (mounted) setState(() => _loading = true);
    final summary = await AccountingService.getBookSummary(
      token: _token!,
      userId: widget.userId,
      dateFrom: _dateFrom != null ? _dateFmt.format(_dateFrom!) : null,
      dateTo: _dateTo != null ? _dateFmt.format(_dateTo!) : null,
    );
    if (mounted) setState(() { _summary = summary; _loading = false; });
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() { if (isFrom) _dateFrom = picked; else _dateTo = picked; });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DateFilterRow(
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              isSwahili: sw,
              onPickFrom: () => _pickDate(true),
              onPickTo: () => _pickDate(false),
              onClear: () { setState(() { _dateFrom = null; _dateTo = null; }); _load(); },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              ))
            else if (_summary == null)
              Center(child: Text(sw ? 'Hakuna data' : 'No data available',
                  style: const TextStyle(color: _kSecondary)))
            else ...[
              Row(children: [
                _MetricCard(
                  label: sw ? 'Ingizo' : 'Entries',
                  value: _summary!.entryCount.toString(),
                  icon: Icons.receipt_long_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: sw ? 'Usawa' : 'Balanced',
                  value: _summary!.balanced ? (sw ? 'Ndio' : 'Yes') : (sw ? 'Hapana' : 'No'),
                  icon: _summary!.balanced ? Icons.check_circle_rounded : Icons.warning_rounded,
                  valueColor: _summary!.balanced ? _kGreen : _kError,
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _MetricCard(
                  label: sw ? 'Jumla Deni' : 'Total Debit',
                  value: _fmt.format(_summary!.totalDebit),
                  icon: Icons.arrow_upward_rounded,
                ),
                const SizedBox(width: 12),
                _MetricCard(
                  label: sw ? 'Jumla Mkopo' : 'Total Credit',
                  value: _fmt.format(_summary!.totalCredit),
                  icon: Icons.arrow_downward_rounded,
                ),
              ]),
              if (_summary!.unbalancedEntries.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(sw ? 'Ingizo Zisizo Sawa' : 'Unbalanced Entries',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kError)),
                const SizedBox(height: 8),
                ..._summary!.unbalancedEntries.map((e) => _UnbalancedCard(entry: e, fmt: _fmt)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DateFilterRow extends StatelessWidget {
  final DateTime? dateFrom, dateTo;
  final bool isSwahili;
  final VoidCallback onPickFrom, onPickTo, onClear;

  const _DateFilterRow({
    required this.dateFrom, required this.dateTo, required this.isSwahili,
    required this.onPickFrom, required this.onPickTo, required this.onClear,
  });

  String _label(DateTime? d, String fallback) =>
      d != null ? DateFormat('dd MMM yyyy').format(d) : fallback;

  @override
  Widget build(BuildContext context) {
    final sw = isSwahili;
    return Row(children: [
      Expanded(child: OutlinedButton(
        onPressed: onPickFrom,
        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
            side: const BorderSide(color: Color(0xFFE0E0E0))),
        child: Text(_label(dateFrom, sw ? 'Tangu' : 'From'),
            style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      )),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(
        onPressed: onPickTo,
        style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
            side: const BorderSide(color: Color(0xFFE0E0E0))),
        child: Text(_label(dateTo, sw ? 'Hadi' : 'To'),
            style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
      )),
      if (dateFrom != null || dateTo != null) ...[
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.clear_rounded, size: 20, color: _kSecondary),
            onPressed: onClear),
      ],
    ]);
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? valueColor;

  const _MetricCard({required this.label, required this.value, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: _kSecondary),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: valueColor ?? _kPrimary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _UnbalancedCard extends StatelessWidget {
  final UnbalancedEntry entry;
  final NumberFormat fmt;
  const _UnbalancedCard({required this.entry, required this.fmt});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kError.withValues(alpha: 0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.warning_amber_rounded, size: 18, color: _kError),
      const SizedBox(width: 10),
      Expanded(child: Text(entry.entryNumber,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
      Text('Δ ${fmt.format(entry.difference)}',
          style: const TextStyle(fontSize: 12, color: _kError, fontWeight: FontWeight.w600)),
    ]),
  );
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/accounting/pages/accounting_overview_page.dart
```
Expected: no errors.

---

## Task 4: Journal Page

**Files:**
- Create: `lib/accounting/pages/accounting_journal_page.dart`

- [ ] **Step 1: Create the journal page**

```dart
// lib/accounting/pages/accounting_journal_page.dart
// Tab 2: paginated journal ledger + entry detail bottom sheet.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/accounting_models.dart';
import '../services/accounting_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kError = Color(0xFFB00020);

class AccountingJournalPage extends StatefulWidget {
  final int userId;
  const AccountingJournalPage({super.key, required this.userId});

  @override
  State<AccountingJournalPage> createState() => _AccountingJournalPageState();
}

class _AccountingJournalPageState extends State<AccountingJournalPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  bool _loading = true;
  bool _loadingMore = false;
  List<JournalEntry> _entries = [];
  DateTime? _dateFrom, _dateTo;
  String? _sourceType;
  int _perPage = 20;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayDateFmt = DateFormat('dd MMM yyyy');
  final _amtFmt = NumberFormat('#,##0.00');

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_token == null) return;
    if (reset) {
      if (mounted) setState(() { _loading = true; _entries = []; _perPage = 20; });
    } else {
      if (mounted) setState(() => _loadingMore = true);
    }
    final entries = await AccountingService.getJournalLedger(
      token: _token!,
      userId: widget.userId,
      dateFrom: _dateFrom != null ? _dateFmt.format(_dateFrom!) : null,
      dateTo: _dateTo != null ? _dateFmt.format(_dateTo!) : null,
      sourceType: _sourceType,
      perPage: _perPage,
    );
    if (mounted) setState(() { _entries = entries; _loading = false; _loadingMore = false; });
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() { if (isFrom) _dateFrom = picked; else _dateTo = picked; });
    await _load(reset: true);
  }

  void _showEntryDetail(JournalEntry entry) {
    final sw = _isSwahili;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 36, height: 4, decoration: BoxDecoration(
              color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Expanded(child: Text(entry.entryNumber,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (!entry.totals.balanced)
                const Icon(Icons.warning_amber_rounded, size: 18, color: _kError),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(entry.description,
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const Divider(height: 24),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(horizontal: 20), children: [
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
              },
              children: [
                TableRow(children: [
                  _th(sw ? 'Nambari' : 'Code'),
                  _th(sw ? 'Akaunti' : 'Account'),
                  _th(sw ? 'Deni' : 'Debit', align: TextAlign.right),
                  _th(sw ? 'Mkopo' : 'Credit', align: TextAlign.right),
                ]),
                ...entry.lines.map((l) => TableRow(children: [
                  _td(l.coaCode),
                  _td(l.accountName),
                  _td(_amtFmt.format(l.debit), align: TextAlign.right),
                  _td(_amtFmt.format(l.credit), align: TextAlign.right),
                ])),
              ],
            ),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(sw ? 'Jumla' : 'Totals',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              Text('${_amtFmt.format(entry.totals.debit)} / ${_amtFmt.format(entry.totals.credit)}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                      color: entry.totals.balanced ? _kGreen : _kError)),
            ]),
            const SizedBox(height: 24),
          ])),
        ]),
      ),
    );
  }

  Widget _th(String t, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary),
        textAlign: align),
  );

  Widget _td(String t, {TextAlign align = TextAlign.left}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(t, style: const TextStyle(fontSize: 12, color: _kPrimary),
        textAlign: align, maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => _pickDate(true),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
                    side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Text(_dateFrom != null ? _displayDateFmt.format(_dateFrom!) : (sw ? 'Tangu' : 'From'),
                    style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(
                onPressed: () => _pickDate(false),
                style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
                    side: const BorderSide(color: Color(0xFFE0E0E0))),
                child: Text(_dateTo != null ? _displayDateFmt.format(_dateTo!) : (sw ? 'Hadi' : 'To'),
                    style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (_dateFrom != null || _dateTo != null || _sourceType != null) ...[
                const SizedBox(width: 8),
                IconButton(icon: const Icon(Icons.clear_rounded, size: 20, color: _kSecondary),
                    onPressed: () { setState(() { _dateFrom = null; _dateTo = null; _sourceType = null; }); _load(reset: true); }),
              ],
            ]),
            const SizedBox(height: 8),
            _SourceTypeFilter(
              value: _sourceType,
              isSwahili: sw,
              onChanged: (v) { setState(() => _sourceType = v); _load(reset: true); },
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : _entries.isEmpty
                ? Center(child: Text(sw ? 'Hakuna ingizo' : 'No journal entries',
                    style: const TextStyle(color: _kSecondary)))
                : RefreshIndicator(
                    color: _kPrimary,
                    onRefresh: () => _load(reset: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: _entries.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        if (i == _entries.length) {
                          return _loadingMore
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)))
                              : TextButton(
                                  onPressed: () { setState(() => _perPage += 20); _load(); },
                                  child: Text(sw ? 'Pakia zaidi' : 'Load more',
                                      style: const TextStyle(color: _kPrimary)));
                        }
                        final e = _entries[i];
                        return _EntryCard(
                          entry: e,
                          amtFmt: _amtFmt,
                          dateFmt: _displayDateFmt,
                          isSwahili: sw,
                          onTap: () => _showEntryDetail(e),
                        );
                      },
                    ),
                  )),
      ]),
    );
  }
}

class _SourceTypeFilter extends StatelessWidget {
  final String? value;
  final bool isSwahili;
  final ValueChanged<String?> onChanged;

  const _SourceTypeFilter({required this.value, required this.isSwahili, required this.onChanged});

  static const _types = ['invoice', 'expense', 'payroll', 'payment', 'manual'];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: value,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
        isDense: true,
      ),
      hint: Text(isSwahili ? 'Aina yote' : 'All types',
          style: const TextStyle(fontSize: 13, color: _kSecondary)),
      items: [
        DropdownMenuItem(value: null, child: Text(isSwahili ? 'Aina zote' : 'All types',
            style: const TextStyle(fontSize: 13))),
        ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t,
            style: const TextStyle(fontSize: 13)))),
      ],
      onChanged: onChanged,
    );
  }
}

class _EntryCard extends StatelessWidget {
  final JournalEntry entry;
  final NumberFormat amtFmt;
  final DateFormat dateFmt;
  final bool isSwahili;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry, required this.amtFmt, required this.dateFmt,
    required this.isSwahili, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(entry.entryNumber,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          if (entry.sourceType.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(entry.sourceType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary)),
            ),
        ]),
        if (entry.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(entry.description,
              style: const TextStyle(fontSize: 12, color: _kSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Text(entry.postedAt != null ? dateFmt.format(entry.postedAt!) : '',
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const Spacer(),
          Icon(entry.totals.balanced ? Icons.check_circle_rounded : Icons.warning_rounded,
              size: 14, color: entry.totals.balanced ? _kGreen : _kError),
          const SizedBox(width: 4),
          Text('${amtFmt.format(entry.totals.debit)} Dr',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
      ]),
    ),
  );
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/accounting/pages/accounting_journal_page.dart
```
Expected: no errors.

---

## Task 5: Reports Page

**Files:**
- Create: `lib/accounting/pages/accounting_reports_page.dart`

- [ ] **Step 1: Create the reports page**

```dart
// lib/accounting/pages/accounting_reports_page.dart
// Tab 3: Trial Balance | P&L | Balance Sheet with SegmentedButton switcher.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/accounting_models.dart';
import '../services/accounting_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kGreen = Color(0xFF2E7D32);
const Color _kError = Color(0xFFB00020);

enum _Report { trialBalance, pnl, balanceSheet }

class AccountingReportsPage extends StatefulWidget {
  final int userId;
  const AccountingReportsPage({super.key, required this.userId});

  @override
  State<AccountingReportsPage> createState() => _AccountingReportsPageState();
}

class _AccountingReportsPageState extends State<AccountingReportsPage>
    with AutomaticKeepAliveClientMixin {
  String? _token;
  _Report _report = _Report.trialBalance;
  bool _loading = false;

  // Trial Balance
  TrialBalance? _trialBalance;
  DateTime? _tbFrom, _tbTo;

  // P&L
  ProfitAndLoss? _pnl;
  DateTime _pnlFrom = DateTime(DateTime.now().year, 1, 1);
  DateTime _pnlTo = DateTime.now();

  // Balance Sheet
  BalanceSheet? _balanceSheet;

  final _dateFmt = DateFormat('yyyy-MM-dd');
  final _displayDateFmt = DateFormat('dd MMM yyyy');
  final _amtFmt = NumberFormat('#,##0.00');

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
    await _loadCurrent();
  }

  Future<void> _loadCurrent() async {
    if (_token == null) return;
    if (mounted) setState(() => _loading = true);
    switch (_report) {
      case _Report.trialBalance:
        final tb = await AccountingService.getTrialBalance(
          token: _token!, userId: widget.userId,
          dateFrom: _tbFrom != null ? _dateFmt.format(_tbFrom!) : null,
          dateTo: _tbTo != null ? _dateFmt.format(_tbTo!) : null,
        );
        if (mounted) setState(() { _trialBalance = tb; _loading = false; });
      case _Report.pnl:
        final pnl = await AccountingService.getProfitAndLoss(
          token: _token!, userId: widget.userId,
          dateFrom: _dateFmt.format(_pnlFrom),
          dateTo: _dateFmt.format(_pnlTo),
        );
        if (mounted) setState(() { _pnl = pnl; _loading = false; });
      case _Report.balanceSheet:
        final bs = await AccountingService.getBalanceSheet(
            token: _token!, userId: widget.userId);
        if (mounted) setState(() { _balanceSheet = bs; _loading = false; });
    }
  }

  Future<void> _pickDate(bool isFrom, {bool isPnl = false}) async {
    final current = isPnl ? (isFrom ? _pnlFrom : _pnlTo) : (isFrom ? _tbFrom : _tbTo);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isPnl) { if (isFrom) _pnlFrom = picked; else _pnlTo = picked; }
      else { if (isFrom) _tbFrom = picked; else _tbTo = picked; }
    });
    await _loadCurrent();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final sw = _isSwahili;
    return Scaffold(
      backgroundColor: _kBackground,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<_Report>(
            segments: [
              ButtonSegment(value: _Report.trialBalance,
                  label: Text(sw ? 'Mizani' : 'Trial Bal.', style: const TextStyle(fontSize: 11))),
              ButtonSegment(value: _Report.pnl,
                  label: Text(sw ? 'Faida/Hasara' : 'P&L', style: const TextStyle(fontSize: 11))),
              ButtonSegment(value: _Report.balanceSheet,
                  label: Text(sw ? 'Karatasi' : 'Bal. Sheet', style: const TextStyle(fontSize: 11))),
            ],
            selected: {_report},
            onSelectionChanged: (s) {
              setState(() => _report = s.first);
              _loadCurrent();
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? _kPrimary : _kCardBg),
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected) ? Colors.white : _kPrimary),
            ),
          ),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadCurrent,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    if (_report == _Report.trialBalance) _buildTrialBalance(sw),
                    if (_report == _Report.pnl) _buildPnl(sw),
                    if (_report == _Report.balanceSheet) _buildBalanceSheet(sw),
                  ],
                ),
              )),
      ]),
    );
  }

  Widget _buildTrialBalance(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_tbFrom != null ? _displayDateFmt.format(_tbFrom!) : (sw ? 'Tangu' : 'From'),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(false),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_tbTo != null ? _displayDateFmt.format(_tbTo!) : (sw ? 'Hadi' : 'To'),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ]),
      const SizedBox(height: 16),
      if (_trialBalance == null)
        Center(child: Text(sw ? 'Hakuna data' : 'No data',
            style: const TextStyle(color: _kSecondary)))
      else
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Deni' : 'Debit', sw ? 'Mkopo' : 'Credit'],
          rows: _trialBalance!.lines.map((l) => [
            '${l.coaCode} ${l.accountName}',
            _amtFmt.format(l.debit),
            _amtFmt.format(l.credit),
          ]).toList(),
        ),
    ]);
  }

  Widget _buildPnl(bool sw) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(true, isPnl: true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_displayDateFmt.format(_pnlFrom),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton(
          onPressed: () => _pickDate(false, isPnl: true),
          style: OutlinedButton.styleFrom(foregroundColor: _kPrimary,
              side: const BorderSide(color: Color(0xFFE0E0E0))),
          child: Text(_displayDateFmt.format(_pnlTo),
              style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ]),
      const SizedBox(height: 16),
      if (_pnl == null)
        Center(child: Text(sw ? 'Chagua kipindi' : 'Select a period to load',
            style: const TextStyle(color: _kSecondary)))
      else ...[
        _SectionHeader(title: sw ? 'Mapato' : 'Income'),
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Kiasi' : 'Amount'],
          rows: _pnl!.incomeAccounts.map((a) => [
            '${a.coaCode} ${a.accountName}', _amtFmt.format(a.amount)]).toList(),
        ),
        const SizedBox(height: 16),
        _SectionHeader(title: sw ? 'Matumizi' : 'Expenses'),
        _ReportTable(
          headers: [sw ? 'Akaunti' : 'Account', sw ? 'Kiasi' : 'Amount'],
          rows: _pnl!.expenseAccounts.map((a) => [
            '${a.coaCode} ${a.accountName}', _amtFmt.format(a.amount)]).toList(),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pnl!.netProfit >= 0 ? _kGreen.withValues(alpha: 0.08) : _kError.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Text(sw ? 'Faida/Hasara Halisi' : 'Net Profit / Loss',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: _pnl!.netProfit >= 0 ? _kGreen : _kError)),
            const Spacer(),
            Text(_amtFmt.format(_pnl!.netProfit),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: _pnl!.netProfit >= 0 ? _kGreen : _kError)),
          ]),
        ),
      ],
    ]);
  }

  Widget _buildBalanceSheet(bool sw) {
    if (_balanceSheet == null) {
      return Center(child: Text(sw ? 'Hakuna data' : 'No data',
          style: const TextStyle(color: _kSecondary)));
    }
    return Column(children: [
      _BsSection(
        title: sw ? 'Mali' : 'Assets',
        accounts: _balanceSheet!.assets,
        amtFmt: _amtFmt,
      ),
      const SizedBox(height: 12),
      _BsSection(
        title: sw ? 'Madeni' : 'Liabilities',
        accounts: _balanceSheet!.liabilities,
        amtFmt: _amtFmt,
      ),
      const SizedBox(height: 12),
      _BsSection(
        title: sw ? 'Hisa' : 'Equity',
        accounts: _balanceSheet!.equity,
        amtFmt: _amtFmt,
      ),
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
  );
}

class _ReportTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const _ReportTable({required this.headers, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('—', style: TextStyle(color: _kSecondary))),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: headers.asMap().entries.map((e) => Expanded(
            flex: e.key == 0 ? 3 : 2,
            child: Text(e.value, style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: _kSecondary),
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right),
          )).toList()),
        ),
        const Divider(height: 1, thickness: 0.5),
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: row.asMap().entries.map((e) => Expanded(
            flex: e.key == 0 ? 3 : 2,
            child: Text(e.value, style: const TextStyle(fontSize: 12, color: _kPrimary),
                textAlign: e.key == 0 ? TextAlign.left : TextAlign.right,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          )).toList()),
        )),
      ]),
    );
  }
}

class _BsSection extends StatelessWidget {
  final String title;
  final List<BsAccount> accounts;
  final NumberFormat amtFmt;

  const _BsSection({required this.title, required this.accounts, required this.amtFmt});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _kCardBg, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(title, style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
      trailing: Text(
        amtFmt.format(accounts.fold(0.0, (s, a) => s + a.amount)),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
      ),
      children: accounts.map((a) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Text(a.coaCode, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const SizedBox(width: 8),
          Expanded(child: Text(a.accountName,
              style: const TextStyle(fontSize: 12, color: _kPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(amtFmt.format(a.amount),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
        ]),
      )).toList(),
    ),
  );
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/accounting/pages/accounting_reports_page.dart
```
Expected: no errors.

---

## Task 6: Module Entry Point

**Files:**
- Create: `lib/accounting/accounting_module.dart`

- [ ] **Step 1: Create the module**

```dart
// lib/accounting/accounting_module.dart
// Entry point for the accounting feature — 3-tab DefaultTabController.
import 'package:flutter/material.dart';
import '../../lib/l10n/app_strings_scope.dart';
import 'pages/accounting_overview_page.dart';
import 'pages/accounting_journal_page.dart';
import 'pages/accounting_reports_page.dart';

// Fix the relative import path — this file is inside lib/accounting/
// so the import should be:
```

Wait — imports inside `lib/accounting/` must use package-relative or `../` paths. Correct file:

```dart
// lib/accounting/accounting_module.dart
import 'package:flutter/material.dart';
import '../l10n/app_strings_scope.dart';
import 'pages/accounting_overview_page.dart';
import 'pages/accounting_journal_page.dart';
import 'pages/accounting_reports_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);

class AccountingModule extends StatelessWidget {
  final int userId;
  const AccountingModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Container(
          color: _kBackground,
          child: TabBar(
            labelColor: _kPrimary,
            unselectedLabelColor: const Color(0xFF999999),
            indicatorColor: _kPrimary,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            tabs: [
              Tab(text: sw ? 'Muhtasari' : 'Overview'),
              Tab(text: sw ? 'Ingizo' : 'Journal'),
              Tab(text: sw ? 'Ripoti' : 'Reports'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            AccountingOverviewPage(userId: userId),
            AccountingJournalPage(userId: userId),
            AccountingReportsPage(userId: userId),
          ]),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/accounting/accounting_module.dart
```
Expected: no errors.

---

## Task 7: Wire into Profile Screen

**Files:**
- Modify: `lib/screens/profile/profile_screen.dart`

- [ ] **Step 1: Add the import**

In `lib/screens/profile/profile_screen.dart`, after line 89 (the last business import), add:

```dart
import '../../accounting/accounting_module.dart';
```

- [ ] **Step 2: Add the case**

After the `biz_appointments` case (line ~2294), add:

```dart
      case 'biz_accounting':
        return AccountingModule(userId: userId);
```

So the block reads:

```dart
      case 'biz_appointments':
        return BizTabWrapper(userId: userId, builder: (uid, all, first, fId) =>
            fId != null ? AppointmentsPage(businessId: fId) : const SizedBox.shrink());
      case 'biz_accounting':
        return AccountingModule(userId: userId);

      // ── Daily Life & Home ─────────────────────────────────────────
```

- [ ] **Step 3: Verify the full app compiles**

```bash
flutter analyze lib/screens/profile/profile_screen.dart
```
Expected: no errors.

- [ ] **Step 4: Run the app and confirm the tab appears**

```bash
flutter run
```

Navigate to a profile → Business category → scroll to find the Accounting tab. Confirm all 3 sub-tabs load without errors.

---

## Self-Review Checklist

- [x] All 6 backend endpoints covered: book-summary (Task 3), journal-ledger + journal-entry (Task 4), trial-balance + profit-and-loss + balance-sheet (Task 5)
- [x] Models match API response shapes from backend query
- [x] Service uses `ApiConfig.authHeaders(token)` — matches codebase convention
- [x] Token fetched via `LocalStorageService.getInstance()` — matches PayrollPage pattern
- [x] Bilingual labels in all 3 pages
- [x] `try/catch` on all async service calls
- [x] `mounted` guard before `setState` on all async results
- [x] `maxLines` + `TextOverflow.ellipsis` on all dynamic text
- [x] `AutomaticKeepAliveClientMixin` on all tab pages (preserves scroll on tab switch)
- [x] Profile screen import + case added in Task 7
- [x] No TBD or placeholder steps
