import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../services/graphql/graphql_dispatch_service.dart';
import '../models/delivery_models.dart';

// Unified delivery dispatch service.
//
// All provider integrations (Sendy, WhatsApp, Piki, AfriDelivery, Lori)
// live in the BACKEND. This service calls the TAJIRI API — no third-party
// credentials ever enter the mobile app.
//
// Backend endpoints:
//   POST /api/shop/orders/{id}/dispatch/quotes  → getQuotes()
//   POST /api/shop/orders/{id}/dispatch         → dispatch()
//   GET  /api/shop/orders/{id}/dispatch/track   → track()

class DeliveryDispatchService {
  DeliveryDispatchService._();
  static final instance = DeliveryDispatchService._();

  static const _timeout = Duration(seconds: 20);

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...ApiConfig.authHeaders(token),
      };

  // ─── Get quotes from all providers ──────────────────────────────

  Future<List<DeliveryQuote>> getQuotes({
    required int orderId,
    required int userId,
    required String token,
    double weightKg = 1.0,
    String? notes,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDispatchService.getQuotes(
        orderId: orderId,
        weightKg: weightKg,
        notes: notes,
      );
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shop/orders/$orderId/dispatch/quotes');
      final response = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'user_id': userId,
              'weight_kg': weightKg,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
            }),
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true) {
        final raw = (json['data']['quotes'] as List?) ?? [];
        return raw.map((q) => _parseQuote(q as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    // Fallback: return all providers as unavailable
    return DeliveryProviderType.values.map((p) => DeliveryQuote(
      provider: p,
      priceTzs: 0,
      available: false,
      unavailableReason: 'Could not reach server',
    )).toList();
  }

  // ─── Dispatch via chosen provider ───────────────────────────────

  Future<DeliveryResult> dispatch({
    required int orderId,
    required int userId,
    required String token,
    required DeliveryProviderType provider,
    double weightKg = 1.0,
    String? notes,
    DateTime? preferredPickupTime,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDispatchService.dispatch(
        orderId: orderId,
        provider: provider,
        weightKg: weightKg,
        notes: notes,
        preferredPickupTime: preferredPickupTime,
      );
    }
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/shop/orders/$orderId/dispatch');
      final response = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'user_id': userId,
              'provider': _providerSlug(provider),
              'weight_kg': weightKg,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
              if (preferredPickupTime != null)
                'preferred_pickup_time': preferredPickupTime.toIso8601String(),
            }),
          )
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        return DeliveryResult(
          success: true,
          provider: provider,
          trackingId: data['tracking_id'] as String?,
          trackingUrl: data['tracking_url'] as String?,
          message: json['message'] as String?,
          rawResponse: data,
        );
      }
      return DeliveryResult.failure(
        provider,
        json['message'] as String? ?? 'Dispatch failed',
      );
    } catch (e) {
      return DeliveryResult.failure(
        provider,
        'Network error: ${e.toString().split('\n').first}',
      );
    }
  }

  // ─── Track a delivery ────────────────────────────────────────────

  Future<DeliveryTracking?> track({
    required int orderId,
    required int userId,
    required String token,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDispatchService.track(orderId: orderId);
    }
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/shop/orders/$orderId/dispatch/track?user_id=$userId',
      );
      final response = await http
          .get(uri, headers: _headers(token))
          .timeout(_timeout);

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>? ?? {};
        final providerSlug = data['provider'] as String?;
        final tracking = data['tracking'] as Map<String, dynamic>?;
        if (tracking == null) return null;

        return DeliveryTracking(
          provider: _slugToProvider(providerSlug ?? 'self'),
          trackingId: data['tracking_id'] as String? ?? '',
          status: _parseTrackingStatus(tracking['status'] as String? ?? ''),
          statusLabel: tracking['status_label'] as String? ?? '',
          riderName: tracking['rider_name'] as String?,
          riderPhone: tracking['rider_phone'] as String?,
          riderLat: (tracking['rider_lat'] as num?)?.toDouble(),
          riderLng: (tracking['rider_lng'] as num?)?.toDouble(),
          updatedAt: tracking['updated_at'] != null
              ? DateTime.tryParse(tracking['updated_at'] as String)
              : null,
        );
      }
    } catch (_) {}
    return null;
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  DeliveryQuote _parseQuote(Map<String, dynamic> q) {
    final providerSlug = q['provider'] as String? ?? 'self';
    final available = q['available'] as bool? ?? false;
    return DeliveryQuote(
      provider: _slugToProvider(providerSlug),
      priceTzs: (q['price_tzs'] as num?)?.toDouble() ?? 0,
      available: available,
      vehicleType: q['vehicle_type'] as String?,
      estimatedDuration: q['eta_minutes'] != null
          ? Duration(minutes: (q['eta_minutes'] as num).toInt())
          : null,
      unavailableReason: q['unavailable_reason'] as String?,
    );
  }

  String _providerSlug(DeliveryProviderType p) {
    switch (p) {
      case DeliveryProviderType.tajiri:       return 'tajiri';
      case DeliveryProviderType.sendy:        return 'sendy';
      case DeliveryProviderType.whatsapp:     return 'whatsapp';
      case DeliveryProviderType.piki:         return 'piki';
      case DeliveryProviderType.afriDelivery: return 'afridelivery';
      case DeliveryProviderType.lori:         return 'lori';
      case DeliveryProviderType.selfDelivery: return 'self';
    }
  }

  DeliveryProviderType _slugToProvider(String slug) {
    switch (slug) {
      case 'tajiri':       return DeliveryProviderType.tajiri;
      case 'sendy':        return DeliveryProviderType.sendy;
      case 'whatsapp':     return DeliveryProviderType.whatsapp;
      case 'piki':         return DeliveryProviderType.piki;
      case 'afridelivery': return DeliveryProviderType.afriDelivery;
      case 'lori':         return DeliveryProviderType.lori;
      default:             return DeliveryProviderType.selfDelivery;
    }
  }

  TrackingStatus _parseTrackingStatus(String s) {
    switch (s) {
      case 'assigned':   return TrackingStatus.assigned;
      case 'picked_up':  return TrackingStatus.pickedUp;
      case 'in_transit': return TrackingStatus.inTransit;
      case 'delivered':  return TrackingStatus.delivered;
      case 'failed':     return TrackingStatus.failed;
      case 'cancelled':  return TrackingStatus.cancelled;
      default:           return TrackingStatus.pending;
    }
  }
}
