import '../../accounting/models/accounting_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL personal accounting reports (Phase 64).
class GraphqlAccountingService {
  static const _bookSummaryFields = r'''
    entryCount
    totalDebit
    totalCredit
    balanced
    unbalancedEntries {
      entryId
      entryNumber
      debit
      credit
      difference
    }
  ''';

  static const _journalEntryFields = r'''
    id
    entryNumber
    description
    sourceType
    sourceId
    postedAt
    lines {
      coaCode
      accountName
      debit
      credit
    }
    totals {
      debit
      credit
      balanced
    }
  ''';

  static const _trialBalanceFields = r'''
    period {
      dateFrom
      dateTo
    }
    lines {
      coaCode
      accountName
      debit
      credit
    }
  ''';

  static const _profitAndLossFields = r'''
    period {
      dateFrom
      dateTo
    }
    incomeAccounts {
      coaCode
      accountName
      amount
    }
    expenseAccounts {
      coaCode
      accountName
      amount
    }
    netProfit
  ''';

  static const _balanceSheetFields = r'''
    assets {
      coaCode
      accountName
      amount
    }
    liabilities {
      coaCode
      accountName
      amount
    }
    equity {
      coaCode
      accountName
      amount
    }
  ''';

  static Map<String, dynamic> _bookSummaryToLegacy(Map<String, dynamic> row) {
    final unbalanced = (row['unbalancedEntries'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((item) => {
              'entry_id': int.parse(item['entryId'].toString()),
              'entry_number': item['entryNumber'],
              'debit': item['debit'],
              'credit': item['credit'],
              'difference': item['difference'],
            })
        .toList();
    return {
      'entry_count': row['entryCount'],
      'total_debit': row['totalDebit'],
      'total_credit': row['totalCredit'],
      'balanced': row['balanced'] == true,
      'unbalanced_entries': unbalanced,
    };
  }

  static Map<String, dynamic> _journalEntryToLegacy(Map<String, dynamic> row) {
    final lines = (row['lines'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((line) => {
              'coa_code': line['coaCode'],
              'account_name': line['accountName'],
              'debit': line['debit'],
              'credit': line['credit'],
            })
        .toList();
    final totals = row['totals'] as Map<String, dynamic>? ?? {};
    return {
      'id': int.parse(row['id'].toString()),
      'entry_number': row['entryNumber'],
      'description': row['description'],
      'source_type': row['sourceType'],
      'source_id': row['sourceId'] != null
          ? int.parse(row['sourceId'].toString())
          : null,
      'posted_at': row['postedAt'],
      'lines': lines,
      'totals': {
        'debit': totals['debit'],
        'credit': totals['credit'],
        'balanced': totals['balanced'] == true,
      },
    };
  }

  static Map<String, dynamic> _trialBalanceToLegacy(Map<String, dynamic> row) {
    final period = row['period'] as Map<String, dynamic>? ?? {};
    final lines = (row['lines'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((line) => {
              'coa_code': line['coaCode'],
              'account_name': line['accountName'],
              'debit': line['debit'],
              'credit': line['credit'],
            })
        .toList();
    return {
      'period': {
        'date_from': period['dateFrom'],
        'date_to': period['dateTo'],
      },
      'lines': lines,
    };
  }

  static Map<String, dynamic> _profitAndLossToLegacy(Map<String, dynamic> row) {
    final period = row['period'] as Map<String, dynamic>? ?? {};
    List<Map<String, dynamic>> parseAccounts(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map((item) => {
            'coa_code': item['coaCode'],
            'account_name': item['accountName'],
            'amount': item['amount'],
          }).toList();
    }

    return {
      'period': {
        'date_from': period['dateFrom'],
        'date_to': period['dateTo'],
      },
      'income_accounts': parseAccounts(row['incomeAccounts']),
      'expense_accounts': parseAccounts(row['expenseAccounts']),
      'net_profit': row['netProfit'],
    };
  }

  static Map<String, dynamic> _balanceSheetToLegacy(Map<String, dynamic> row) {
    List<Map<String, dynamic>> parseAccounts(dynamic raw) {
      if (raw is! List) return [];
      return raw.whereType<Map<String, dynamic>>().map((item) => {
            'coa_code': item['coaCode'],
            'account_name': item['accountName'],
            'amount': item['amount'],
          }).toList();
    }

    return {
      'assets': parseAccounts(row['assets']),
      'liabilities': parseAccounts(row['liabilities']),
      'equity': parseAccounts(row['equity']),
    };
  }

  static Future<BookSummary?> getBookSummary({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingBookSummary(\$dateFrom: String, \$dateTo: String) {
          accountingBookSummary(dateFrom: \$dateFrom, dateTo: \$dateTo) {
            $_bookSummaryFields
          }
        }
      ''',
      variables: {
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      },
    );
    final row = data['accountingBookSummary'] as Map<String, dynamic>?;
    if (row == null) return null;
    return BookSummary.fromJson(_bookSummaryToLegacy(row));
  }

  static Future<List<JournalEntry>> getJournalLedger({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
    String? sourceType,
    int perPage = 20,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingJournalLedger(
          \$page: Int
          \$perPage: Int
          \$dateFrom: String
          \$dateTo: String
          \$sourceType: String
        ) {
          accountingJournalLedger(
            page: \$page
            perPage: \$perPage
            dateFrom: \$dateFrom
            dateTo: \$dateTo
            sourceType: \$sourceType
          ) {
            items {
              $_journalEntryFields
            }
          }
        }
      ''',
      variables: {
        'page': 1,
        'perPage': perPage,
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
        if (sourceType != null) 'sourceType': sourceType,
      },
    );
    final connection = data['accountingJournalLedger'] as Map<String, dynamic>?;
    final items = connection?['items'] as List? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map((row) => JournalEntry.fromJson(_journalEntryToLegacy(row)))
        .toList();
  }

  static Future<JournalEntry?> getJournalEntry({
    required String token,
    required int userId,
    required int entryId,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingJournalEntry(\$entryId: ID!) {
          accountingJournalEntry(entryId: \$entryId) {
            $_journalEntryFields
          }
        }
      ''',
      variables: {'entryId': entryId.toString()},
    );
    final row = data['accountingJournalEntry'] as Map<String, dynamic>?;
    if (row == null) return null;
    return JournalEntry.fromJson(_journalEntryToLegacy(row));
  }

  static Future<TrialBalance?> getTrialBalance({
    required String token,
    required int userId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingTrialBalance(\$dateFrom: String, \$dateTo: String) {
          accountingTrialBalance(dateFrom: \$dateFrom, dateTo: \$dateTo) {
            $_trialBalanceFields
          }
        }
      ''',
      variables: {
        if (dateFrom != null) 'dateFrom': dateFrom,
        if (dateTo != null) 'dateTo': dateTo,
      },
    );
    final row = data['accountingTrialBalance'] as Map<String, dynamic>?;
    if (row == null) return null;
    return TrialBalance.fromJson(_trialBalanceToLegacy(row));
  }

  static Future<ProfitAndLoss?> getProfitAndLoss({
    required String token,
    required int userId,
    required String dateFrom,
    required String dateTo,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingProfitAndLoss(\$dateFrom: String!, \$dateTo: String!) {
          accountingProfitAndLoss(dateFrom: \$dateFrom, dateTo: \$dateTo) {
            $_profitAndLossFields
          }
        }
      ''',
      variables: {
        'dateFrom': dateFrom,
        'dateTo': dateTo,
      },
    );
    final row = data['accountingProfitAndLoss'] as Map<String, dynamic>?;
    if (row == null) return null;
    return ProfitAndLoss.fromJson(_profitAndLossToLegacy(row));
  }

  static Future<BalanceSheet?> getBalanceSheet({
    required String token,
    required int userId,
  }) async {
    final data = await TajiriGraphqlClient.query(
      token: token,
      document: '''
        query AccountingBalanceSheet {
          accountingBalanceSheet {
            $_balanceSheetFields
          }
        }
      ''',
    );
    final row = data['accountingBalanceSheet'] as Map<String, dynamic>?;
    if (row == null) return null;
    return BalanceSheet.fromJson(_balanceSheetToLegacy(row));
  }
}
