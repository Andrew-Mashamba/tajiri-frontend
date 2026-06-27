import '../../budget/models/budget_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL budget ledger — income & expenditure (Phase 31).
class GraphqlBudgetService {
  static const _incomeFields = r'''
    id
    userId
    amount
    source
    sourceModule
    description
    referenceId
    metadata
    date
    isRecurring
    createdAt
  ''';

  static const _expenditureFields = r'''
    id
    userId
    amount
    category
    sourceModule
    description
    referenceId
    envelopeTag
    metadata
    date
    isRecurring
    createdAt
  ''';

  static final Map<String, String?> _incomeCursors = {};
  static final Map<String, String?> _expenditureCursors = {};

  static Map<String, dynamic> _incomeToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'amount': (row['amount'] as num).toDouble(),
      'source': row['source'],
      'source_module': row['sourceModule'],
      'description': row['description'] ?? '',
      'reference_id': row['referenceId'],
      'metadata': row['metadata'],
      'date': row['date'],
      'is_recurring': row['isRecurring'] == true,
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _expenditureToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'amount': (row['amount'] as num).toDouble(),
      'category': row['category'],
      'source_module': row['sourceModule'],
      'description': row['description'] ?? '',
      'reference_id': row['referenceId'],
      'envelope_tag': row['envelopeTag'],
      'metadata': row['metadata'],
      'date': row['date'],
      'is_recurring': row['isRecurring'] == true,
      'created_at': row['createdAt'],
    };
  }

  static Future<IncomeRecord?> recordIncome({
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
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordBudgetIncome(\$input: RecordBudgetIncomeInput!) {
          recordBudgetIncome(input: \$input) {
            $_incomeFields
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'source': source,
            'description': description,
            if (sourceModule != null) 'sourceModule': sourceModule,
            if (referenceId != null) 'referenceId': referenceId,
            if (metadata != null) 'metadata': metadata,
            if (date != null) 'date': date.toIso8601String(),
            'isRecurring': isRecurring,
          },
        },
        auth: true,
      );
      final row = data['recordBudgetIncome'] as Map<String, dynamic>? ?? {};
      return IncomeRecord.fromJson(_incomeToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<IncomeListResult> getIncome({
    String? source,
    String? sourceModule,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final cacheKey =
          'income:${source ?? 'all'}:${sourceModule ?? 'all'}:${from?.toIso8601String() ?? 'all'}:${to?.toIso8601String() ?? 'all'}';
      final cursor = page <= 1 ? null : _incomeCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetIncome(\$source: String, \$sourceModule: String, \$fromDate: String, \$toDate: String, \$cursor: String) {
          myBudgetIncome(source: \$source, sourceModule: \$sourceModule, fromDate: \$fromDate, toDate: \$toDate, cursor: \$cursor) {
            items { $_incomeFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (source != null) 'source': source,
          if (sourceModule != null) 'sourceModule': sourceModule,
          if (from != null) 'fromDate': from.toIso8601String(),
          if (to != null) 'toDate': to.toIso8601String(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['myBudgetIncome'] as Map<String, dynamic>? ?? {};
      final records = (pageData['items'] as List? ?? [])
          .map((r) => IncomeRecord.fromJson(_incomeToLegacy(r as Map<String, dynamic>)))
          .toList();
      _incomeCursors[cacheKey] = pageData['nextCursor']?.toString();
      return IncomeListResult(success: true, records: records);
    } catch (e) {
      return IncomeListResult(success: false, message: e.toString());
    }
  }

  static Future<IncomeSummary?> getIncomeSummary({required String period}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetIncomeSummary(\$period: String!) {
          myBudgetIncomeSummary(period: \$period) {
            totalIncome
            bySource
            byModule
            transactionCount
            trend
          }
        }
        ''',
        variables: {'period': period},
        auth: true,
      );
      final summary = data['myBudgetIncomeSummary'] as Map<String, dynamic>? ?? {};
      return IncomeSummary.fromJson({
        'total_income': summary['totalIncome'],
        'by_source': summary['bySource'],
        'by_module': summary['byModule'],
        'transaction_count': summary['transactionCount'],
        'trend': summary['trend'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, double>> getIncomeBySource({
    required int year,
    required int month,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetIncomeBySource(\$year: Int!, \$month: Int!) {
          myBudgetIncomeBySource(year: \$year, month: \$month)
        }
        ''',
        variables: {'year': year, 'month': month},
        auth: true,
      );
      final raw = data['myBudgetIncomeBySource'] as Map<String, dynamic>? ?? {};
      return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static Future<List<RecurringIncome>> getRecurringIncome() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyRecurringIncome {
          myRecurringIncome {
            id
            description
            amount
            source
            frequency
            lastOccurrence
            nextExpected
          }
        }
        ''',
        auth: true,
      );
      return (data['myRecurringIncome'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return RecurringIncome.fromJson({
          'id': item['id'],
          'description': item['description'],
          'amount': item['amount'],
          'source': item['source'],
          'frequency': item['frequency'],
          'last_occurrence': item['lastOccurrence'],
          'next_expected': item['nextExpected'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<ExpenditureRecord?> recordExpenditure({
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
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordBudgetExpenditure(\$input: RecordBudgetExpenditureInput!) {
          recordBudgetExpenditure(input: \$input) {
            $_expenditureFields
          }
        }
        ''',
        variables: {
          'input': {
            'amount': amount,
            'category': category,
            'description': description,
            if (sourceModule != null) 'sourceModule': sourceModule,
            if (referenceId != null) 'referenceId': referenceId,
            if (envelopeTag != null) 'envelopeTag': envelopeTag,
            if (metadata != null) 'metadata': metadata,
            if (date != null) 'date': date.toIso8601String(),
            'isRecurring': isRecurring,
          },
        },
        auth: true,
      );
      final row = data['recordBudgetExpenditure'] as Map<String, dynamic>? ?? {};
      return ExpenditureRecord.fromJson(_expenditureToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<ExpenditureListResult> getExpenditures({
    String? category,
    String? sourceModule,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final cacheKey =
          'exp:${category ?? 'all'}:${sourceModule ?? 'all'}:${from?.toIso8601String() ?? 'all'}:${to?.toIso8601String() ?? 'all'}';
      final cursor = page <= 1 ? null : _expenditureCursors[cacheKey];
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetExpenditures(\$category: String, \$sourceModule: String, \$fromDate: String, \$toDate: String, \$cursor: String) {
          myBudgetExpenditures(category: \$category, sourceModule: \$sourceModule, fromDate: \$fromDate, toDate: \$toDate, cursor: \$cursor) {
            items { $_expenditureFields }
            nextCursor
            hasMore
          }
        }
        ''',
        variables: {
          if (category != null) 'category': category,
          if (sourceModule != null) 'sourceModule': sourceModule,
          if (from != null) 'fromDate': from.toIso8601String(),
          if (to != null) 'toDate': to.toIso8601String(),
          if (cursor != null) 'cursor': cursor,
        },
        auth: true,
      );
      final pageData = data['myBudgetExpenditures'] as Map<String, dynamic>? ?? {};
      final records = (pageData['items'] as List? ?? [])
          .map((r) => ExpenditureRecord.fromJson(_expenditureToLegacy(r as Map<String, dynamic>)))
          .toList();
      _expenditureCursors[cacheKey] = pageData['nextCursor']?.toString();
      return ExpenditureListResult(success: true, records: records);
    } catch (e) {
      return ExpenditureListResult(success: false, message: e.toString());
    }
  }

  static Future<ExpenditureSummary?> getExpenditureSummary({required String period}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetExpenditureSummary(\$period: String!) {
          myBudgetExpenditureSummary(period: \$period) {
            totalSpent
            byCategory
            byModule
            transactionCount
            trend
          }
        }
        ''',
        variables: {'period': period},
        auth: true,
      );
      final summary = data['myBudgetExpenditureSummary'] as Map<String, dynamic>? ?? {};
      return ExpenditureSummary.fromJson({
        'total_spent': summary['totalSpent'],
        'by_category': summary['byCategory'],
        'by_module': summary['byModule'],
        'transaction_count': summary['transactionCount'],
        'trend': summary['trend'],
      });
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, double>> getExpenditureByCategory({
    required int year,
    required int month,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetExpenditureByCategory(\$year: Int!, \$month: Int!) {
          myBudgetExpenditureByCategory(year: \$year, month: \$month)
        }
        ''',
        variables: {'year': year, 'month': month},
        auth: true,
      );
      final raw = data['myBudgetExpenditureByCategory'] as Map<String, dynamic>? ?? {};
      return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {};
    }
  }

  static Future<List<RecurringExpense>> getRecurringExpenses() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyRecurringExpenses {
          myRecurringExpenses {
            id
            description
            amount
            category
            frequency
            lastOccurrence
            nextExpected
            isConfirmed
          }
        }
        ''',
        auth: true,
      );
      return (data['myRecurringExpenses'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return RecurringExpense.fromJson({
          'id': item['id'],
          'description': item['description'],
          'amount': item['amount'],
          'category': item['category'],
          'frequency': item['frequency'],
          'last_occurrence': item['lastOccurrence'],
          'next_expected': item['nextExpected'],
          'is_confirmed': item['isConfirmed'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> confirmRecurringExpense(int expenseId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ConfirmRecurringExpense(\$expenseId: ID!) {
          confirmRecurringExpense(expenseId: \$expenseId) { id }
        }
        ''',
        variables: {'expenseId': expenseId.toString()},
        auth: true,
      );
      return data['confirmRecurringExpense'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> dismissRecurringExpense(int expenseId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DismissRecurringExpense(\$expenseId: ID!) {
          dismissRecurringExpense(expenseId: \$expenseId)
        }
        ''',
        variables: {'expenseId': expenseId.toString()},
        auth: true,
      );
      return data['dismissRecurringExpense'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<UpcomingExpense>> getUpcomingExpenses() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyUpcomingExpenses {
          myUpcomingExpenses {
            description
            amount
            category
            expectedDate
            isRecurring
          }
        }
        ''',
        auth: true,
      );
      return (data['myUpcomingExpenses'] as List? ?? []).map((row) {
        final item = row as Map<String, dynamic>;
        return UpcomingExpense.fromJson({
          'description': item['description'],
          'amount': item['amount'],
          'category': item['category'],
          'expected_date': item['expectedDate'],
          'is_recurring': item['isRecurring'],
        });
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> recategorizeExpenditure(int expenditureId, String newCategory) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecategorizeBudgetExpenditure(\$expenditureId: ID!, \$category: String!) {
          recategorizeBudgetExpenditure(expenditureId: \$expenditureId, category: \$category) {
            id
          }
        }
        ''',
        variables: {
          'expenditureId': expenditureId.toString(),
          'category': newCategory,
        },
        auth: true,
      );
      return data['recategorizeBudgetExpenditure'] != null;
    } catch (_) {
      return false;
    }
  }

  static Future<SpendingPace?> getSpendingPace({
    required String category,
    required int year,
    required int month,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MySpendingPace(\$category: String!, \$year: Int!, \$month: Int!) {
          mySpendingPace(category: \$category, year: \$year, month: \$month) {
            category
            allocated
            spent
            remaining
            daysRemaining
            dailyAllowance
            projectedTotal
            status
          }
        }
        ''',
        variables: {'category': category, 'year': year, 'month': month},
        auth: true,
      );
      final pace = data['mySpendingPace'] as Map<String, dynamic>? ?? {};
      return SpendingPace.fromJson({
        'category': pace['category'],
        'allocated': pace['allocated'],
        'spent': pace['spent'],
        'remaining': pace['remaining'],
        'days_remaining': pace['daysRemaining'],
        'daily_allowance': pace['dailyAllowance'],
        'projected_total': pace['projectedTotal'],
        'status': pace['status'],
      });
    } catch (_) {
      return null;
    }
  }

  static const _envelopeDefaultFields = r'''
    id
    nameEn
    nameSw
    icon
    color
    sortOrder
    groupName
    moduleTag
    isActive
  ''';

  static const _envelopeFields = r'''
    id
    userId
    defaultId
    nameEn
    nameSw
    icon
    color
    sortOrder
    moduleTag
    allocatedAmount
    spentAmount
    isVisible
    rollover
    rolledOverAmount
    year
    month
  ''';

  static const _goalFields = r'''
    id
    userId
    name
    icon
    targetAmount
    savedAmount
    deadline
    createdAt
  ''';

  static const _streakFields = r'''
    currentStreak
    longestStreak
    lastCheckDate
    freezeUsed
    badges
  ''';

  static Map<String, dynamic> _envelopeDefaultToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name_en': row['nameEn'],
      'name_sw': row['nameSw'],
      'icon': row['icon'],
      'color': row['color'],
      'sort_order': row['sortOrder'],
      'group_name': row['groupName'],
      'module_tag': row['moduleTag'],
      'is_active': row['isActive'] == true,
    };
  }

  static Map<String, dynamic> _envelopeToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'default_id': row['defaultId'] != null
          ? int.parse(row['defaultId'].toString())
          : null,
      'name_en': row['nameEn'],
      'name_sw': row['nameSw'],
      'icon': row['icon'],
      'color': row['color'],
      'sort_order': row['sortOrder'],
      'module_tag': row['moduleTag'],
      'allocated_amount': (row['allocatedAmount'] as num).toDouble(),
      'spent_amount': (row['spentAmount'] as num).toDouble(),
      'is_visible': row['isVisible'] == true,
      'rollover': row['rollover'] == true,
      'rolled_over_amount': (row['rolledOverAmount'] as num).toDouble(),
      'year': row['year'],
      'month': row['month'],
    };
  }

  static Map<String, dynamic> _goalToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'name': row['name'],
      'icon': row['icon'],
      'target_amount': (row['targetAmount'] as num).toDouble(),
      'saved_amount': (row['savedAmount'] as num).toDouble(),
      'deadline': row['deadline'],
      'created_at': row['createdAt'],
    };
  }

  static Map<String, dynamic> _streakToLegacy(Map<String, dynamic> row) {
    return {
      'current_streak': row['currentStreak'],
      'longest_streak': row['longestStreak'],
      'last_check_date': row['lastCheckDate'],
      'freeze_used': row['freezeUsed'] == true,
      'badges': row['badges'] ?? [],
    };
  }

  static Map<String, dynamic> _periodToLegacy(Map<String, dynamic> row) {
    return {
      'user_id': int.parse(row['userId'].toString()),
      'year': row['year'],
      'month': row['month'],
      'total_income': (row['totalIncome'] as num).toDouble(),
      'total_allocated': (row['totalAllocated'] as num).toDouble(),
      'total_spent': (row['totalSpent'] as num).toDouble(),
      'wallet_balance': (row['walletBalance'] as num).toDouble(),
      'savings_rate': (row['savingsRate'] as num).toDouble(),
    };
  }

  static Map<String, dynamic> _createEnvelopeInput(Map<String, dynamic> data) {
    return {
      'nameEn': data['name_en'] ?? data['nameEn'] ?? '',
      'nameSw': data['name_sw'] ?? data['nameSw'] ?? '',
      if (data['icon'] != null) 'icon': data['icon'],
      if (data['color'] != null) 'color': data['color'],
      if (data['sort_order'] != null) 'sortOrder': data['sort_order'],
      if (data['sortOrder'] != null) 'sortOrder': data['sortOrder'],
      if (data['module_tag'] != null) 'moduleTag': data['module_tag'],
      if (data['moduleTag'] != null) 'moduleTag': data['moduleTag'],
      if (data['default_id'] != null) 'defaultId': data['default_id'].toString(),
      if (data['defaultId'] != null) 'defaultId': data['defaultId'].toString(),
      if (data['allocated_amount'] != null)
        'allocatedAmount': data['allocated_amount'],
      if (data['allocatedAmount'] != null) 'allocatedAmount': data['allocatedAmount'],
      if (data.containsKey('is_visible')) 'isVisible': data['is_visible'],
      if (data.containsKey('isVisible')) 'isVisible': data['isVisible'],
      if (data.containsKey('rollover')) 'rollover': data['rollover'],
      if (data['rolled_over_amount'] != null)
        'rolledOverAmount': data['rolled_over_amount'],
      if (data['rolledOverAmount'] != null)
        'rolledOverAmount': data['rolledOverAmount'],
      if (data['year'] != null) 'year': data['year'],
      if (data['month'] != null) 'month': data['month'],
    };
  }

  static Map<String, dynamic> _updateEnvelopeInput(Map<String, dynamic> data) {
    final input = <String, dynamic>{};
    if (data['name_en'] != null) input['nameEn'] = data['name_en'];
    if (data['nameEn'] != null) input['nameEn'] = data['nameEn'];
    if (data['name_sw'] != null) input['nameSw'] = data['name_sw'];
    if (data['nameSw'] != null) input['nameSw'] = data['nameSw'];
    if (data['icon'] != null) input['icon'] = data['icon'];
    if (data['color'] != null) input['color'] = data['color'];
    if (data['sort_order'] != null) input['sortOrder'] = data['sort_order'];
    if (data['sortOrder'] != null) input['sortOrder'] = data['sortOrder'];
    if (data['module_tag'] != null) input['moduleTag'] = data['module_tag'];
    if (data['moduleTag'] != null) input['moduleTag'] = data['moduleTag'];
    if (data['allocated_amount'] != null) {
      input['allocatedAmount'] = data['allocated_amount'];
    }
    if (data['allocatedAmount'] != null) {
      input['allocatedAmount'] = data['allocatedAmount'];
    }
    if (data.containsKey('is_visible')) input['isVisible'] = data['is_visible'];
    if (data.containsKey('isVisible')) input['isVisible'] = data['isVisible'];
    if (data.containsKey('rollover')) input['rollover'] = data['rollover'];
    if (data['rolled_over_amount'] != null) {
      input['rolledOverAmount'] = data['rolled_over_amount'];
    }
    if (data['rolledOverAmount'] != null) {
      input['rolledOverAmount'] = data['rolledOverAmount'];
    }
    return input;
  }

  static Map<String, dynamic> _createGoalInput(Map<String, dynamic> data) {
    return {
      'name': data['name'],
      if (data['icon'] != null) 'icon': data['icon'],
      'targetAmount': data['target_amount'] ?? data['targetAmount'],
      if (data['saved_amount'] != null) 'savedAmount': data['saved_amount'],
      if (data['savedAmount'] != null) 'savedAmount': data['savedAmount'],
      if (data['deadline'] != null) 'deadline': data['deadline'],
    };
  }

  static Map<String, dynamic> _updateGoalInput(Map<String, dynamic> data) {
    final input = <String, dynamic>{};
    if (data['name'] != null) input['name'] = data['name'];
    if (data['icon'] != null) input['icon'] = data['icon'];
    if (data['target_amount'] != null) {
      input['targetAmount'] = data['target_amount'];
    }
    if (data['targetAmount'] != null) input['targetAmount'] = data['targetAmount'];
    if (data['saved_amount'] != null) input['savedAmount'] = data['saved_amount'];
    if (data['savedAmount'] != null) input['savedAmount'] = data['savedAmount'];
    if (data['deadline'] != null) input['deadline'] = data['deadline'];
    return input;
  }

  static Future<List<EnvelopeDefault>> getEnvelopeDefaults() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query BudgetEnvelopeDefaults {
          budgetEnvelopeDefaults {
            $_envelopeDefaultFields
          }
        }
        ''',
        auth: true,
      );
      return (data['budgetEnvelopeDefaults'] as List? ?? []).map((row) {
        return EnvelopeDefault.fromJson(
          _envelopeDefaultToLegacy(row as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<BudgetEnvelope>> getUserEnvelopes({int? year, int? month}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetEnvelopes(\$year: Int, \$month: Int) {
          myBudgetEnvelopes(year: \$year, month: \$month) {
            $_envelopeFields
          }
        }
        ''',
        variables: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
        auth: true,
      );
      return (data['myBudgetEnvelopes'] as List? ?? []).map((row) {
        return BudgetEnvelope.fromJson(
          _envelopeToLegacy(row as Map<String, dynamic>),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<BudgetEnvelope?> createEnvelope(Map<String, dynamic> data) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBudgetEnvelope(\$input: CreateBudgetEnvelopeInput!) {
          createBudgetEnvelope(input: \$input) {
            $_envelopeFields
          }
        }
        ''',
        variables: {'input': _createEnvelopeInput(data)},
        auth: true,
      );
      final row = result['createBudgetEnvelope'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetEnvelope.fromJson(_envelopeToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<BudgetEnvelope?> updateEnvelope(
    int envelopeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBudgetEnvelope(\$envelopeId: ID!, \$input: UpdateBudgetEnvelopeInput!) {
          updateBudgetEnvelope(envelopeId: \$envelopeId, input: \$input) {
            $_envelopeFields
          }
        }
        ''',
        variables: {
          'envelopeId': envelopeId.toString(),
          'input': _updateEnvelopeInput(data),
        },
        auth: true,
      );
      final row = result['updateBudgetEnvelope'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetEnvelope.fromJson(_envelopeToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<BudgetPeriod?> getPeriod({int? year, int? month}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetPeriod(\$year: Int, \$month: Int) {
          myBudgetPeriod(year: \$year, month: \$month) {
            userId
            year
            month
            totalIncome
            totalAllocated
            totalSpent
            walletBalance
            savingsRate
          }
        }
        ''',
        variables: {
          if (year != null) 'year': year,
          if (month != null) 'month': month,
        },
        auth: true,
      );
      final row = data['myBudgetPeriod'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetPeriod.fromJson(_periodToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<List<BudgetGoal>> getGoals() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetGoals {
          myBudgetGoals {
            $_goalFields
          }
        }
        ''',
        auth: true,
      );
      return (data['myBudgetGoals'] as List? ?? []).map((row) {
        return BudgetGoal.fromJson(_goalToLegacy(row as Map<String, dynamic>));
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<BudgetGoal?> createGoal(Map<String, dynamic> data) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateBudgetGoal(\$input: CreateBudgetGoalInput!) {
          createBudgetGoal(input: \$input) {
            $_goalFields
          }
        }
        ''',
        variables: {'input': _createGoalInput(data)},
        auth: true,
      );
      final row = result['createBudgetGoal'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetGoal.fromJson(_goalToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<BudgetGoal?> updateGoal(
    int goalId,
    Map<String, dynamic> data,
  ) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation UpdateBudgetGoal(\$goalId: ID!, \$input: UpdateBudgetGoalInput!) {
          updateBudgetGoal(goalId: \$goalId, input: \$input) {
            $_goalFields
          }
        }
        ''',
        variables: {
          'goalId': goalId.toString(),
          'input': _updateGoalInput(data),
        },
        auth: true,
      );
      final row = result['updateBudgetGoal'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetGoal.fromJson(_goalToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteGoal(int goalId) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation DeleteBudgetGoal(\$goalId: ID!) {
          deleteBudgetGoal(goalId: \$goalId)
        }
        ''',
        variables: {'goalId': goalId.toString()},
        auth: true,
      );
      return result['deleteBudgetGoal'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<BudgetStreak> getStreak() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetStreak {
          myBudgetStreak {
            $_streakFields
          }
        }
        ''',
        auth: true,
      );
      final row = data['myBudgetStreak'] as Map<String, dynamic>?;
      if (row == null) return BudgetStreak();
      return BudgetStreak.fromJson(_streakToLegacy(row));
    } catch (_) {
      return BudgetStreak();
    }
  }

  static Future<BudgetStreak?> checkInStreak(bool allWithinBudget) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CheckInBudgetStreak(\$allWithinBudget: Boolean!) {
          checkInBudgetStreak(allWithinBudget: \$allWithinBudget) {
            $_streakFields
          }
        }
        ''',
        variables: {'allWithinBudget': allWithinBudget},
        auth: true,
      );
      final row = result['checkInBudgetStreak'] as Map<String, dynamic>?;
      if (row == null) return null;
      return BudgetStreak.fromJson(_streakToLegacy(row));
    } catch (_) {
      return null;
    }
  }

  static const _notificationFields = r'''
    id
    userId
    type
    title
    message
    payload
    isRead
    createdAt
  ''';

  static Map<String, dynamic> _notificationToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'type': row['type'],
      'title': row['title'],
      'message': row['message'],
      'payload': row['payload'] ?? {},
      'is_read': row['isRead'] == true,
      'created_at': row['createdAt'],
    };
  }

  static Future<List<Map<String, dynamic>>> checkNotifications() async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CheckBudgetNotifications {
          checkBudgetNotifications {
            $_notificationFields
          }
        }
        ''',
        auth: true,
      );
      final rows = result['checkBudgetNotifications'] as List<dynamic>? ?? [];
      return rows
          .map((row) => _notificationToLegacy(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 50,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyBudgetNotifications(\$limit: Int) {
          myBudgetNotifications(limit: \$limit) {
            $_notificationFields
          }
        }
        ''',
        variables: {'limit': limit},
        auth: true,
      );
      final rows = data['myBudgetNotifications'] as List<dynamic>? ?? [];
      return rows
          .map((row) => _notificationToLegacy(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
