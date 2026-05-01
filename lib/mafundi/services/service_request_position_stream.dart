import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/api_config.dart';

/// Spec F4 #23 — Live ETA push (customer side).
///
/// Subscribes to the `private-service-request.{id}` Reverb channel and emits
/// [PartnerPositionEvent]s as they arrive. Hosts (the customer's service
/// request status page) wire the stream into a `LiveEtaMap`.
///
/// Uses the same socket/auth dance as `CallChannelService`: connect →
/// receive `pusher:connection_established` with a `socket_id` → POST that to
/// `/broadcasting/auth` along with the channel name → send `pusher:subscribe`
/// with the returned `auth` token.
class PartnerPositionEvent {
  final int serviceRequestId;
  final int partnerUserId;
  final double lat;
  final double lng;
  final int? etaMinutes;
  final int? headingDeg;
  final DateTime ts;

  const PartnerPositionEvent({
    required this.serviceRequestId,
    required this.partnerUserId,
    required this.lat,
    required this.lng,
    this.etaMinutes,
    this.headingDeg,
    required this.ts,
  });

  factory PartnerPositionEvent.fromJson(Map<String, dynamic> json) {
    DateTime parseTs(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return PartnerPositionEvent(
      serviceRequestId: (json['service_request_id'] as num?)?.toInt() ?? 0,
      partnerUserId: (json['partner_user_id'] as num?)?.toInt() ?? 0,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      headingDeg: (json['heading_deg'] as num?)?.toInt(),
      ts: parseTs(json['ts']),
    );
  }
}

class ServiceRequestPositionStream {
  final int serviceRequestId;
  final int viewerUserId;
  final String? authToken;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  String? _socketId;
  bool _subscribed = false;
  Timer? _pingTimer;

  final _controller = StreamController<PartnerPositionEvent>.broadcast();
  Stream<PartnerPositionEvent> get stream => _controller.stream;

  ServiceRequestPositionStream({
    required this.serviceRequestId,
    required this.viewerUserId,
    this.authToken,
  });

  /// Best-effort kick-off. Pulls last-known position via REST first so the
  /// map has something to show before the first WS event arrives.
  Future<void> start() async {
    await _seedFromRest();
    await _connectWebSocket();
  }

  Future<void> dispose() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    await _sub?.cancel();
    _sub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    await _controller.close();
  }

  Future<void> _seedFromRest() async {
    try {
      final url = ApiConfig.sanitizeUrl(
          '${ApiConfig.baseUrl}/api/service-requests/$serviceRequestId/partner-position')!;
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      if (body is! Map<String, dynamic>) return;
      if (body['lat'] == null || body['lng'] == null) return;
      final partnerId = (body['partner_user_id'] as num?)?.toInt() ?? 0;
      final ev = PartnerPositionEvent(
        serviceRequestId: serviceRequestId,
        partnerUserId: partnerId,
        lat: (body['lat'] as num).toDouble(),
        lng: (body['lng'] as num).toDouble(),
        etaMinutes: (body['eta_minutes'] as num?)?.toInt(),
        headingDeg: (body['heading_deg'] as num?)?.toInt(),
        ts: body['updated_at'] != null
            ? DateTime.tryParse(body['updated_at'].toString())?.toLocal() ??
                DateTime.now()
            : DateTime.now(),
      );
      if (!_controller.isClosed) _controller.add(ev);
    } catch (e) {
      debugPrint('[PositionStream] seed error: $e');
    }
  }

  Future<void> _connectWebSocket() async {
    final wsUrl = ApiConfig.reverbWsUrl ?? ApiConfig.reverbWsUrlResolved;
    if (wsUrl == null || wsUrl.isEmpty) {
      debugPrint('[PositionStream] no Reverb URL configured');
      return;
    }
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      await _channel!.ready;
      _sub = _channel!.stream.listen(_handleMessage,
          onError: (e) {
            debugPrint('[PositionStream] ws error: $e');
          },
          onDone: () => debugPrint('[PositionStream] ws done'),
          cancelOnError: false);
    } catch (e) {
      debugPrint('[PositionStream] ws connect failed: $e');
    }
  }

  Future<void> _handleMessage(dynamic raw) async {
    if (_controller.isClosed) return;
    try {
      final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = decoded['event'] as String? ?? '';
      if (event == 'pusher:connection_established') {
        final data = decoded['data'];
        Map<String, dynamic>? dataMap;
        if (data is String) dataMap = jsonDecode(data) as Map<String, dynamic>;
        if (data is Map) dataMap = data.cast<String, dynamic>();
        _socketId = dataMap?['socket_id'] as String?;
        if (_socketId != null) {
          await _subscribePrivate();
        }
        _startPing();
        return;
      }
      if (event == 'pusher_internal:subscription_succeeded') {
        _subscribed = true;
        return;
      }
      if (event == 'partner.position') {
        final data = decoded['data'];
        Map<String, dynamic>? dataMap;
        if (data is String) dataMap = jsonDecode(data) as Map<String, dynamic>;
        if (data is Map) dataMap = data.cast<String, dynamic>();
        if (dataMap != null) {
          _controller.add(PartnerPositionEvent.fromJson(dataMap));
        }
      }
    } catch (e) {
      debugPrint('[PositionStream] parse error: $e');
    }
  }

  Future<void> _subscribePrivate() async {
    final channelName = 'private-service-request.$serviceRequestId';
    final auth = await _authChannel(channelName);
    if (auth == null || _channel == null) {
      debugPrint('[PositionStream] auth failed — cannot subscribe');
      return;
    }
    _channel!.sink.add(jsonEncode({
      'event': 'pusher:subscribe',
      'data': {
        'channel': channelName,
        'auth': auth,
      },
    }));
  }

  Future<String?> _authChannel(String channelName) async {
    if (_socketId == null) return null;
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (authToken != null && authToken!.isNotEmpty) {
        headers['Authorization'] = 'Bearer $authToken';
      }
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/broadcasting/auth'),
        headers: headers,
        body: jsonEncode({
          'socket_id': _socketId,
          'channel_name': channelName,
          'user_id': viewerUserId,
        }),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is Map && data['auth'] != null) return data['auth'] as String;
    } catch (e) {
      debugPrint('[PositionStream] auth exception: $e');
    }
    return null;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      try {
        _channel?.sink.add(jsonEncode({'event': 'pusher:ping', 'data': {}}));
      } catch (_) {}
    });
  }

  bool get isSubscribed => _subscribed;
}
