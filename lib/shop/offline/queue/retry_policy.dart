// Generated for docs/shop/shop.md — see offline/queue/retry_policy.dart
/// Exponential backoff caps for mutation replay.
class RetryPolicy {
  static const int maxAttempts = 3;
  static Duration delayForAttempt(int n) => Duration(seconds: (n + 1).clamp(1, 8));
}
