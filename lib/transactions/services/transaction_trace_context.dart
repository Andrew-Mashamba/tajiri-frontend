// Active trace id for correlating HTTP/Dio calls with CentralTransactionService.

class TransactionTraceContext {
  TransactionTraceContext._();

  static String? _traceId;

  /// Current trace from the last [enter] not yet cleared by [clearIfMatches].
  static String? get currentTraceId => _traceId;

  static void enter(String traceId) {
    _traceId = traceId;
  }

  static void clearIfMatches(String traceId) {
    if (_traceId == traceId) {
      _traceId = null;
    }
  }
}
