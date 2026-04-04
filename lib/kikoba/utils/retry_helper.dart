import 'dart:async';
import 'package:logger/logger.dart';

final _logger = Logger(
  printer: PrettyPrinter(methodCount: 0, colors: true, printEmojis: true),
);

/// Retry an async operation with exponential backoff
///
/// Parameters:
/// - [operation] The async operation to retry
/// - [maxRetries] Maximum number of retry attempts (default: 3)
/// - [initialDelay] Initial delay before first retry (default: 1 second)
/// - [maxDelay] Maximum delay between retries (default: 30 seconds)
/// - [retryIf] Optional condition to check if retry should happen
/// - [onRetry] Optional callback when a retry occurs
///
/// Example:
/// ```dart
/// final result = await retryWithBackoff(
///   () => HttpService.vote(...),
///   maxRetries: 3,
///   onRetry: (attempt, error) => print('Retry $attempt: $error'),
/// );
/// ```
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  bool Function(Exception)? retryIf,
  void Function(int attempt, Exception error)? onRetry,
}) async {
  int attempt = 0;
  Duration delay = initialDelay;

  while (true) {
    try {
      attempt++;
      return await operation();
    } on Exception catch (e) {
      // Check if we should retry this type of error
      if (retryIf != null && !retryIf(e)) {
        _logger.w('🚫 Error not retryable: $e');
        rethrow;
      }

      // Check if we've exhausted retries
      if (attempt >= maxRetries) {
        _logger.e('❌ Max retries ($maxRetries) exceeded');
        rethrow;
      }

      // Log retry attempt
      _logger.w('⚠️ Attempt $attempt failed: $e');
      _logger.i('⏳ Retrying in ${delay.inMilliseconds}ms...');

      // Call retry callback if provided
      onRetry?.call(attempt, e);

      // Wait before retry
      await Future.delayed(delay);

      // Exponential backoff with max cap
      delay = Duration(
        milliseconds: (delay.inMilliseconds * 2).clamp(0, maxDelay.inMilliseconds),
      );
    }
  }
}

/// Retry an async operation with fixed delay
Future<T> retryWithFixedDelay<T>(
  Future<T> Function() operation, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
  bool Function(Exception)? retryIf,
}) async {
  int attempt = 0;

  while (true) {
    try {
      attempt++;
      return await operation();
    } on Exception catch (e) {
      if (retryIf != null && !retryIf(e)) rethrow;
      if (attempt >= maxRetries) rethrow;

      _logger.w('⚠️ Attempt $attempt failed, retrying in ${delay.inSeconds}s...');
      await Future.delayed(delay);
    }
  }
}

/// Check if an error is a network-related error worth retrying
bool isNetworkError(Exception e) {
  final message = e.toString().toLowerCase();
  return message.contains('socket') ||
         message.contains('connection') ||
         message.contains('timeout') ||
         message.contains('network') ||
         message.contains('host');
}

/// Check if an error is a server error (5xx) worth retrying
bool isServerError(Exception e) {
  final message = e.toString().toLowerCase();
  return message.contains('500') ||
         message.contains('502') ||
         message.contains('503') ||
         message.contains('504');
}

/// Combined check for retryable errors
bool isRetryableError(Exception e) {
  return isNetworkError(e) || isServerError(e);
}

/// Wrapper for operations that need timeout + retry
Future<T> withTimeoutAndRetry<T>(
  Future<T> Function() operation, {
  Duration timeout = const Duration(seconds: 30),
  int maxRetries = 3,
}) async {
  return retryWithBackoff(
    () => operation().timeout(timeout),
    maxRetries: maxRetries,
    retryIf: (e) => e is TimeoutException || isRetryableError(e),
  );
}
