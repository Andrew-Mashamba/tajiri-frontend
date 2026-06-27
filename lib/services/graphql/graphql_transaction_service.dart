import '../../transactions/models/transaction_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL recorded transactions ledger (Phase 52).
class GraphqlTransactionService {
  static const _transactionFields = r'''
    id traceId status module action direction amount currency
    referenceId businessId metadata startedAt completedAt failedAt message
  ''';

  static Map<String, dynamic> _transactionFromGql(Map<String, dynamic> row) => {
        'id': row['id'],
        'trace_id': row['traceId'],
        'status': row['status'],
        'module': row['module'],
        'action': row['action'],
        'direction': row['direction'],
        'amount': row['amount'],
        'currency': row['currency'],
        'reference_id': row['referenceId'],
        'business_id': row['businessId'],
        'metadata': row['metadata'] ?? {},
        'started_at': row['startedAt'],
        'completed_at': row['completedAt'],
        'failed_at': row['failedAt'],
        'message': row['message'],
      };

  static Future<TransactionListResult> listRecordedTransactions({
    int? businessId,
    int page = 1,
    int perPage = 40,
    String? status,
    String? direction,
    String? module,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query RecordedTransactions(
          \$businessId: ID
          \$page: Int!
          \$perPage: Int!
          \$status: String
          \$direction: String
          \$module: String
        ) {
          recordedTransactions(
            businessId: \$businessId
            page: \$page
            perPage: \$perPage
            status: \$status
            direction: \$direction
            module: \$module
          ) {
            items { $_transactionFields }
            currentPage
            lastPage
            total
          }
        }
        ''',
        variables: {
          if (businessId != null) 'businessId': businessId.toString(),
          'page': page,
          'perPage': perPage,
          if (status != null) 'status': status,
          if (direction != null) 'direction': direction,
          if (module != null) 'module': module,
        },
        auth: true,
      );
      final conn = data['recordedTransactions'];
      if (conn is! Map<String, dynamic>) {
        return TransactionListResult(success: false, message: 'Invalid response');
      }
      final itemsRaw = conn['items'];
      final items = itemsRaw is List
          ? itemsRaw
              .whereType<Map<String, dynamic>>()
              .map((e) => RecordedTransaction.fromJson(_transactionFromGql(e)))
              .toList()
          : <RecordedTransaction>[];
      return TransactionListResult(
        success: true,
        items: items,
        meta: TransactionListMeta(
          currentPage: conn['currentPage'] as int? ?? page,
          lastPage: conn['lastPage'] as int? ?? 1,
          total: conn['total'] as int? ?? items.length,
        ),
        source: TransactionDataSource.api,
      );
    } catch (e) {
      return TransactionListResult(
        success: false,
        message: e.toString(),
        source: TransactionDataSource.api,
      );
    }
  }

  static Future<void> recordTransaction(Map<String, dynamic> body) async {
    try {
      await TajiriGraphqlClient.instance.mutate(
        '''
        mutation RecordTransaction(\$input: RecordTransactionInput!) {
          recordTransaction(input: \$input) { id }
        }
        ''',
        variables: {
          'input': {
            'traceId': body['trace_id'] ?? body['traceId'],
            'status': body['status'],
            'module': body['module'] ?? '',
            'action': body['action'] ?? '',
            'direction': body['direction'] ?? 'outgoing',
            'amount': body['amount'] ?? 0,
            'currency': body['currency'] ?? 'TZS',
            if (body['business_id'] != null)
              'businessId': body['business_id'].toString(),
            if (body['reference_id'] != null) 'referenceId': body['reference_id'],
            if (body['metadata'] != null) 'metadata': body['metadata'],
            if (body['started_at'] != null) 'startedAt': body['started_at'],
            if (body['completed_at'] != null) 'completedAt': body['completed_at'],
            if (body['failed_at'] != null) 'failedAt': body['failed_at'],
            if (body['message'] != null) 'message': body['message'],
            if (body['error_code'] != null) 'errorCode': body['error_code'],
          },
        },
        auth: true,
      );
    } catch (_) {
      // Non-blocking by design — matches REST recorder behavior.
    }
  }
}
