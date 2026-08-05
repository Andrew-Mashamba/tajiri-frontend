// Driver Service — HTTP wrapper for all TAJIRI Delivery driver endpoints.
// All methods are static; pass the auth token and userId on each call.
//
// Backend base path: /api/tajiri-delivery/ (REST) or GraphQL when USE_GRAPHQL=true.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../config/api_config.dart';
import '../../../../services/graphql/graphql_driver_service.dart';
import '../../models/tajiri_delivery_models.dart';

class DriverService {
  DriverService._();

  static const _timeout = Duration(seconds: 20);
  static const String _base = '${ApiConfig.baseUrl}/tajiri-delivery';

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...ApiConfig.authHeaders(token),
      };

  // ─── Online status ──────────────────────────────────────────────

  /// Mark driver as online and ready to receive jobs.
  static Future<bool> goOnline(String token, int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.goOnline();
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/driver/online'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Mark driver as offline.
  static Future<bool> goOffline(String token, int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.goOffline();
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/driver/offline'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Location ───────────────────────────────────────────────────

  /// Push current GPS position to the backend (and Firebase via backend).
  static Future<bool> updateLocation(
    String token,
    int userId,
    double lat,
    double lng,
    double heading,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.updateLocation(lat, lng, heading);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/driver/location'),
            headers: _headers(token),
            body: jsonEncode({
              'user_id': userId,
              'lat': lat,
              'lng': lng,
              'heading': heading,
            }),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Job list ────────────────────────────────────────────────────

  /// Fetch available jobs near the driver (backend handles geo-matching).
  static Future<List<TajiriDeliveryJob>> getAvailableJobs(
    String token,
    int userId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.getAvailableJobs();
    }
    try {
      final res = await http
          .get(
            Uri.parse('$_base/jobs/available?user_id=$userId'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final list = (json['data'] as List?) ?? [];
        return list
            .map((j) => TajiriDeliveryJob.fromJson(j as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  // ─── Accept / lifecycle ──────────────────────────────────────────

  /// Accept a job. Returns the updated job with driver info populated.
  static Future<TajiriDeliveryJob?> acceptJob(
    String token,
    int userId,
    int jobId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.acceptJob(jobId);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/jobs/$jobId/accept'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) return TajiriDeliveryJob.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  /// Confirm that the package has been physically picked up.
  static Future<bool> confirmPickup(
    String token,
    int userId,
    int jobId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.confirmPickup(jobId);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/jobs/$jobId/pickup'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Confirm that the package has been delivered.
  static Future<bool> confirmDelivery(
    String token,
    int userId,
    int jobId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.confirmDelivery(jobId);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/jobs/$jobId/deliver'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Cancel an accepted job with a reason.
  static Future<bool> cancelJob(
    String token,
    int userId,
    int jobId,
    String reason,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.cancelJob(jobId, reason);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/jobs/$jobId/cancel'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId, 'reason': reason}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Active job ──────────────────────────────────────────────────

  /// Returns the driver's currently active job, or null if none.
  static Future<TajiriDeliveryJob?> getActiveJob(
    String token,
    int userId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.getActiveJob();
    }
    try {
      final res = await http
          .get(
            Uri.parse('$_base/driver/active-job?user_id=$userId'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null && data.isNotEmpty) {
          return TajiriDeliveryJob.fromJson(data);
        }
      }
    } catch (_) {}
    return null;
  }

  // ─── COD cash collection ────────────────────────────────────────

  /// Confirm cash collected from customer for a COD order.
  static Future<bool> collectCashPayment(
    int jobId,
    double amount,
    String token, {
    required int userId,
  }) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.collectCashPayment(jobId, amount);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$_base/jobs/$jobId/collect-cash'),
            headers: _headers(token),
            body: jsonEncode({'user_id': userId, 'amount': amount}),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      return res.statusCode == 200 && json['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Earnings ───────────────────────────────────────────────────

  /// Returns raw earnings data: total, today, week, month, recent jobs list.
  static Future<Map<String, dynamic>> getEarnings(
    String token,
    int userId,
  ) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.getEarnings();
    }
    try {
      final res = await http
          .get(
            Uri.parse('$_base/driver/earnings?user_id=$userId'),
            headers: _headers(token),
          )
          .timeout(_timeout);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && json['success'] == true) {
        return json['data'] as Map<String, dynamic>? ?? {};
      }
    } catch (_) {}
    return {};
  }

  /// Live job status for buyer/seller tracking screens.
  static Future<TajiriDeliveryJob?> getJobStatus(int jobId, {String? token}) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlDriverService.getJobStatus(jobId);
    }
    return null;
  }
}
