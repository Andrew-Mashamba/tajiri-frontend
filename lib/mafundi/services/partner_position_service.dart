import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec F4 #23 — Live ETA push (partner side).
///
/// While the partner has tapped "En route" on a service request, this service
/// runs in the foreground, listens to a [Geolocator] position stream every
/// 10 seconds, and POSTs the position to
/// `/api/service-requests/{id}/partner-position`. The backend persists the
/// latest position and broadcasts a `partner.position` Reverb event to the
/// customer's `service-request.{id}` channel.
class PartnerPositionService {
  PartnerPositionService._();
  static final PartnerPositionService instance = PartnerPositionService._();

  StreamSubscription<Position>? _sub;
  int? _serviceRequestId;
  int? _partnerUserId;
  DateTime _lastSent = DateTime.fromMillisecondsSinceEpoch(0);

  Future<bool> start({
    required int serviceRequestId,
    required int partnerUserId,
  }) async {
    await stop();
    final allowed = await _ensurePermission();
    if (!allowed) {
      debugPrint('[PartnerPosition] permission denied — cannot start');
      return false;
    }
    _serviceRequestId = serviceRequestId;
    _partnerUserId = partnerUserId;
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(_handlePosition, onError: (e) {
      debugPrint('[PartnerPosition] stream error: $e');
    });
    debugPrint('[PartnerPosition] started for service_request=$serviceRequestId');
    return true;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _serviceRequestId = null;
    _partnerUserId = null;
  }

  bool get isRunning => _sub != null;

  Future<bool> _ensurePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _handlePosition(Position p) async {
    final reqId = _serviceRequestId;
    final partnerId = _partnerUserId;
    if (reqId == null || partnerId == null) return;

    final now = DateTime.now();
    if (now.difference(_lastSent).inSeconds < 10) return;
    _lastSent = now;

    try {
      final url = ApiConfig.sanitizeUrl(
          '${ApiConfig.baseUrl}/api/service-requests/$reqId/partner-position')!;
      await http.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'partner_user_id': partnerId,
          'lat': p.latitude,
          'lng': p.longitude,
          if (p.heading.isFinite) 'heading_deg': p.heading.round(),
          if (p.speed.isFinite) 'speed_kmh': (p.speed * 3.6).round(),
        }),
      );
    } catch (e) {
      debugPrint('[PartnerPosition] post failed: $e');
    }
  }
}
