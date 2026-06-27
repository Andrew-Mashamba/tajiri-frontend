import 'auto_credit_service.dart' show AutoCreditResult;
import 'tajiri_graphql_client.dart';

/// GraphQL auto-credit self-report (Phase 38).
class GraphqlAutoCreditService {
  static Future<AutoCreditResult?> selfReport({
    required int orderId,
    required String orderKind,
    required String reason,
    required int amountTzs,
  }) async {
    try {
      final result = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation ReportAutoCredit(\$input: ReportAutoCreditInput!) {
          reportAutoCredit(input: \$input) {
            ok
            decision
            amountTzs
            aiScore
            message
          }
        }
        ''',
        variables: {
          'input': {
            'orderId': orderId.toString(),
            'orderKind': orderKind,
            'reason': reason,
            'amountTzs': amountTzs,
          },
        },
        auth: true,
      );
      final row = result['reportAutoCredit'] as Map<String, dynamic>?;
      if (row == null) return null;
      return AutoCreditResult(
        ok: row['ok'] == true,
        decision: row['decision']?.toString() ?? 'review',
        amountTzs: (row['amountTzs'] as num?)?.toInt(),
        aiScore: (row['aiScore'] as num?)?.toDouble(),
        message: row['message']?.toString(),
      );
    } catch (_) {
      return null;
    }
  }
}
