import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/graphql/graphql_transaction_service.dart';
import 'transaction_local_store.dart';
import 'transaction_trace_context.dart';

String get _baseUrl => ApiConfig.baseUrl;

class CentralTransactionService {
  static String _newTraceId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rnd = Random().nextInt(1 << 32).toRadixString(16);
    return 'txn_${now}_$rnd';
  }

  static Future<String> start({
    required String token,
    required String module,
    required String action,
    required String direction, // incoming | outgoing
    required double amount,
    String currency = 'TZS',
    String? actorId,
    int? businessId,
    Map<String, dynamic>? metadata,
  }) async {
    final traceId = _newTraceId();
    final body = <String, dynamic>{
      'trace_id': traceId,
      'status': 'pending',
      'module': module,
      'action': action,
      'direction': direction,
      'amount': amount,
      'currency': currency,
      if (actorId != null) 'actor_id': actorId,
      if (businessId != null) 'business_id': businessId,
      if (metadata != null) 'metadata': metadata,
      'started_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _send(token: token, body: body, attachTraceHeader: false);
    TransactionTraceContext.enter(traceId);
    await TransactionLocalStore.putSnapshot(traceId, body);
    return traceId;
  }

  static Future<void> complete({
    required String token,
    required String traceId,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _send(
        token: token,
        attachTraceHeader: true,
        body: {
          'trace_id': traceId,
          'status': 'success',
          if (referenceId != null) 'reference_id': referenceId,
          if (metadata != null) 'metadata': metadata,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } finally {
      TransactionTraceContext.clearIfMatches(traceId);
      await TransactionLocalStore.remove(traceId);
    }
  }

  static Future<void> fail({
    required String token,
    required String traceId,
    String? errorCode,
    String? message,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _send(
        token: token,
        attachTraceHeader: true,
        body: {
          'trace_id': traceId,
          'status': 'failed',
          if (errorCode != null) 'error_code': errorCode,
          if (message != null) 'message': message,
          if (metadata != null) 'metadata': metadata,
          'failed_at': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } finally {
      TransactionTraceContext.clearIfMatches(traceId);
      await TransactionLocalStore.remove(traceId);
    }
  }

  static Future<void> _send({
    required String token,
    required Map<String, dynamic> body,
    bool attachTraceHeader = true,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      await GraphqlTransactionService.recordTransaction(body);
      return;
    }
    try {
      final hdr = attachTraceHeader
          ? ApiConfig.authHeaders(token)
          : ApiConfig.authHeadersWithoutTrace(token);
      final res = await http.post(
        Uri.parse('$_baseUrl/transactions/record'),
        headers: hdr,
        body: jsonEncode(body),
      );
      if (res.statusCode >= 400) {
        // Non-blocking by design; transaction source flow must continue.
      }
    } catch (_) {
      // Intentionally swallow: recorder failures must not block core transaction.
    }
  }
}
