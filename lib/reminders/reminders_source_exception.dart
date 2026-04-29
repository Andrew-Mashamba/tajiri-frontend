/// When true, strict Vikumbusho treats the HTTP response as an **empty feed** for
/// that source instead of failing the whole merge (expired token, scope, or
/// route auth). Server errors (5xx) still surface via [RemindersSourceException].
bool reminderStrictSkipHttpStatus(int statusCode) {
  return statusCode == 401 || statusCode == 403;
}

/// Thrown when a Vikumbusho feed fails in [strict] mode (scheduling / full refresh).
class RemindersSourceException implements Exception {
  RemindersSourceException(this.sourceLabel, this.statusCode, {this.cause});

  final String sourceLabel;
  final int statusCode;
  final Object? cause;

  @override
  String toString() =>
      'RemindersSourceException($sourceLabel, HTTP $statusCode${cause != null ? ', $cause' : ''})';
}
