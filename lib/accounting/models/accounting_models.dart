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
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
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
    List<PnlAccount> parseAccounts(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(PnlAccount.fromJson).toList();
    }
    return ProfitAndLoss(
      dateFrom: from,
      dateTo: to,
      incomeAccounts: parseAccounts(j['income_accounts']),
      expenseAccounts: parseAccounts(j['expense_accounts']),
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
    List<BsAccount> parse(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map(BsAccount.fromJson).toList();
    }
    return BalanceSheet(
      assets: parse(j['assets']),
      liabilities: parse(j['liabilities']),
      equity: parse(j['equity']),
    );
  }
}
