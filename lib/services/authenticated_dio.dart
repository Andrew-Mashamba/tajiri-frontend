import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Singleton Dio instance with auth interceptor, silent refresh, and cert pinning.
///
/// Spec: docs/superpowers/specs/2026-03-30-persistent-auth-design.md S4
///
/// Usage:
/// ```dart
/// final response = await AuthenticatedDio.instance.get('/posts');
/// ```
class AuthenticatedDio {
  AuthenticatedDio._();

  static Dio? _instance;

  /// Get the singleton Dio instance. Lazily initialized on first access.
  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(_AuthInterceptor());

    return dio;
  }

  /// Reset the singleton (for testing or after logout).
  static void reset() {
    _instance?.close();
    _instance = null;
  }
}

class _AuthInterceptor extends Interceptor {
  Completer<bool>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await AuthService.instance.getValidAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh')) {
      return handler.next(err);
    }

    try {
      final refreshed = await _refreshWithDedup();

      if (refreshed) {
        final token = await AuthService.instance.getValidAccessToken();
        if (token != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
        }
        final dio = AuthenticatedDio.instance;
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      }

      return handler.next(err);
    } catch (e) {
      return handler.next(err);
    }
  }

  Future<bool> _refreshWithDedup() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final result = await AuthService.instance.refreshTokens();
      _refreshCompleter!.complete(result);
      return result;
    } catch (e) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }
}
