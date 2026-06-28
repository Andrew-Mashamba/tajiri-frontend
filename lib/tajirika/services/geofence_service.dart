import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/http_retry.dart';
import '../../config/api_config.dart';
import '../../services/graphql/graphql_tajirika_ops_service.dart';

class GeofenceService {
  static Future<GeofenceCheckResult> check({
    required int partnerUserId,
    required int orderId,
    required String orderSource,
    required double lat,
    required double lng,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaOpsService.checkGeofence(
        partnerUserId: partnerUserId,
        orderId: orderId,
        orderSource: orderSource,
        lat: lat,
        lng: lng,
      );
    }
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/geofence/check'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': partnerUserId,
          'order_id': orderId,
          'order_source': orderSource,
          'lat': lat,
          'lng': lng,
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final d = body['data'];
        return GeofenceCheckResult(
          success: true,
          distanceMeters: d['distance_meters'] ?? 0,
          inside100m: d['inside_100m'] ?? false,
          inside500m: d['inside_500m'] ?? false,
          status: d['status'] ?? 'idle',
          eventId: d['event_id'],
        );
      }
      return GeofenceCheckResult(
        success: false,
        message: body['message']?.toString() ?? 'Check failed',
      );
    } catch (e) {
      return GeofenceCheckResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<EtaResult> eta({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaOpsService.geofenceEta(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
      );
    }
    try {
      final res = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/geofence/eta').replace(queryParameters: {
          'from_lat': '$fromLat',
          'from_lng': '$fromLng',
          'to_lat': '$toLat',
          'to_lng': '$toLng',
        }),
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['success'] == true) {
        final d = body['data'];
        return EtaResult(
          success: true,
          distanceMeters: d['distance_meters'] ?? 0,
          etaSeconds: d['eta_seconds'] ?? 0,
          etaText: d['eta_text'] ?? '',
        );
      }
      return EtaResult(success: false, message: body['message']?.toString() ?? 'ETA failed');
    } catch (e) {
      return EtaResult(success: false, message: 'Kosa: $e');
    }
  }

  static Future<List<GeofenceEvent>> events({
    int? partnerUserId,
    int? orderId,
    int limit = 50,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlTajirikaOpsService.listGeofenceEvents(
        partnerUserId: partnerUserId,
        orderId: orderId,
        limit: limit,
      );
    }
    try {
      final params = <String, String>{'limit': '$limit'};
      if (partnerUserId != null) params['partner_user_id'] = '$partnerUserId';
      if (orderId != null) params['order_id'] = '$orderId';
      final res = await httpGetWithRetry(
        Uri.parse('${ApiConfig.baseUrl}/geofence/events').replace(queryParameters: params),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => GeofenceEvent.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class GeofenceCheckResult {
  final bool success;
  final String? message;
  final int distanceMeters;
  final bool inside100m;
  final bool inside500m;
  final String status;
  final int? eventId;

  const GeofenceCheckResult({
    required this.success,
    this.message,
    this.distanceMeters = 0,
    this.inside100m = false,
    this.inside500m = false,
    this.status = 'idle',
    this.eventId,
  });
}

class EtaResult {
  final bool success;
  final String? message;
  final int distanceMeters;
  final int etaSeconds;
  final String etaText;

  const EtaResult({
    required this.success,
    this.message,
    this.distanceMeters = 0,
    this.etaSeconds = 0,
    this.etaText = '',
  });
}

class GeofenceEvent {
  final int id;
  final int partnerUserId;
  final int orderId;
  final String orderSource;
  final int distanceMeters;
  final DateTime createdAt;

  const GeofenceEvent({
    required this.id,
    required this.partnerUserId,
    required this.orderId,
    required this.orderSource,
    required this.distanceMeters,
    required this.createdAt,
  });

  factory GeofenceEvent.fromJson(Map<String, dynamic> j) {
    return GeofenceEvent(
      id: j['id'] ?? 0,
      partnerUserId: j['partner_user_id'] ?? 0,
      orderId: j['order_id'] ?? 0,
      orderSource: j['order_source'] ?? '',
      distanceMeters: j['distance_meters'] ?? 0,
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
