// Lightweight retry wrapper for idempotent HTTP GETs.
//
// The Dart `http` package's default IOClient pools keep-alive sockets. When
// the server or an upstream proxy (Cloudflare, nginx) closes an idle socket
// the client may still pick it from the pool, send the request, and get
// `ClientException: Connection closed before full header was received` back
// before any response header arrives. The fix is to retry once on a fresh
// Client, which is guaranteed not to reuse the dead socket.
//
// Only safe for idempotent verbs — do NOT extend this to POST/PUT/PATCH.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

Future<http.Response> httpGetWithRetry(
  Uri uri, {
  Map<String, String>? headers,
}) async {
  try {
    return await http.get(uri, headers: headers);
  } on http.ClientException catch (e) {
    if (!_isTransientConnectionError(e.message)) rethrow;
    debugPrint('[httpGetWithRetry] Transient error on $uri (${e.message}) — retrying once on fresh client');
  } on SocketException catch (e) {
    debugPrint('[httpGetWithRetry] SocketException on $uri (${e.message}) — retrying once on fresh client');
  } on HttpException catch (e) {
    if (!_isTransientConnectionError(e.message)) rethrow;
    debugPrint('[httpGetWithRetry] Transient HttpException on $uri (${e.message}) — retrying once on fresh client');
  }

  final client = http.Client();
  try {
    return await client.get(uri, headers: headers);
  } finally {
    client.close();
  }
}

/// Same retry strategy as [httpGetWithRetry], but for services that hold their
/// own persistent [http.Client] (typically for test injection). The first
/// attempt uses the provided client so connection reuse still works; the
/// retry uses a brand-new client so we never resurrect the dead socket from
/// the persistent client's pool.
Future<http.Response> httpClientGetWithRetry(
  http.Client client,
  Uri uri, {
  Map<String, String>? headers,
}) async {
  try {
    return await client.get(uri, headers: headers);
  } on http.ClientException catch (e) {
    if (!_isTransientConnectionError(e.message)) rethrow;
    debugPrint('[httpClientGetWithRetry] Transient error on $uri (${e.message}) — retrying once on fresh client');
  } on SocketException catch (e) {
    debugPrint('[httpClientGetWithRetry] SocketException on $uri (${e.message}) — retrying once on fresh client');
  } on HttpException catch (e) {
    if (!_isTransientConnectionError(e.message)) rethrow;
    debugPrint('[httpClientGetWithRetry] Transient HttpException on $uri (${e.message}) — retrying once on fresh client');
  }

  final fresh = http.Client();
  try {
    return await fresh.get(uri, headers: headers);
  } finally {
    fresh.close();
  }
}

bool _isTransientConnectionError(String message) {
  final m = message.toLowerCase();
  return m.contains('connection closed before full header was received') ||
      m.contains('connection reset') ||
      m.contains('connection terminated') ||
      m.contains('broken pipe');
}
