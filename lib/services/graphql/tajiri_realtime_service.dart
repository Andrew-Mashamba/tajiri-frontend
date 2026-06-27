import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/api_config.dart';

/// Native WebSocket for greenfield backend `/ws/events` (message.new push).
class TajiriRealtimeService {
  TajiriRealtimeService._();
  static final TajiriRealtimeService instance = TajiriRealtimeService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _accessTokenKey = 'tajiri_access_token';

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onEvent => _events.stream;

  Future<void> connect() async {
    if (!ApiConfig.useGraphqlBackend) return;
    if (_channel != null) return;

    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return;

    final base = ApiConfig.graphqlUrl.replaceFirst(RegExp(r'/graphql/?$'), '');
    final uri = Uri.parse('$base/ws/events').replace(queryParameters: {'token': token});

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _subscription = _channel!.stream.listen((raw) {
        try {
          final map = jsonDecode(raw as String) as Map<String, dynamic>;
          _events.add(map);
        } catch (e) {
          if (kDebugMode) debugPrint('[TajiriRealtimeService] parse: $e');
        }
      }, onError: (e) {
        if (kDebugMode) debugPrint('[TajiriRealtimeService] error: $e');
        disconnect();
      }, onDone: disconnect);
      if (kDebugMode) debugPrint('[TajiriRealtimeService] connected');
    } catch (e) {
      if (kDebugMode) debugPrint('[TajiriRealtimeService] connect failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }
}
