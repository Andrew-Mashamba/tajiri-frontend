// Phase 1.4 + 1.7 — creator onboarding (Tajirika auto-prov banner) and
// wellness (off-day mode) state.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/graphql/graphql_creator_metrics_service.dart';
import '../../services/http_retry.dart';

class CreatorOnboardingState {
  final DateTime? tajirikaAutoProvisionedAt;
  final DateTime? tajirikaBannerDismissedAt;
  final bool tajirikaShowBanner;
  final bool offDayMode;

  const CreatorOnboardingState({
    this.tajirikaAutoProvisionedAt,
    this.tajirikaBannerDismissedAt,
    this.tajirikaShowBanner = false,
    this.offDayMode = false,
  });

  factory CreatorOnboardingState.fromJson(Map<String, dynamic> data) {
    final tajirika = (data['tajirika'] as Map?)?.cast<String, dynamic>() ?? const {};
    final wellness = (data['wellness'] as Map?)?.cast<String, dynamic>() ?? const {};
    return CreatorOnboardingState(
      tajirikaAutoProvisionedAt: _parseDate(tajirika['auto_provisioned_at']),
      tajirikaBannerDismissedAt: _parseDate(tajirika['banner_dismissed_at']),
      tajirikaShowBanner: tajirika['show_banner'] == true,
      offDayMode: wellness['off_day_mode'] == true,
    );
  }

  CreatorOnboardingState copyWith({
    bool? tajirikaShowBanner,
    bool? offDayMode,
    DateTime? tajirikaBannerDismissedAt,
  }) =>
      CreatorOnboardingState(
        tajirikaAutoProvisionedAt: tajirikaAutoProvisionedAt,
        tajirikaBannerDismissedAt:
            tajirikaBannerDismissedAt ?? this.tajirikaBannerDismissedAt,
        tajirikaShowBanner: tajirikaShowBanner ?? this.tajirikaShowBanner,
        offDayMode: offDayMode ?? this.offDayMode,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v is String && v.isNotEmpty) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}

class CreatorOnboardingService {
  String get _base => ApiConfig.baseUrl;

  Future<CreatorOnboardingState?> fetch(int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      final data = await GraphqlCreatorMetricsService.getOnboarding();
      if (data == null) return null;
      return CreatorOnboardingState.fromJson(data);
    }
    try {
      final resp = await httpGetWithRetry(
        Uri.parse('$_base/creators/$userId/onboarding'),
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      if (body['success'] != true) return null;
      return CreatorOnboardingState.fromJson(
          (body['data'] as Map).cast<String, dynamic>());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CreatorOnboardingService] fetch error: $e');
      }
      return null;
    }
  }

  Future<bool> dismissTajirikaBanner(int userId) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCreatorMetricsService.dismissTajirikaBanner();
    }
    try {
      final resp = await http.post(
        Uri.parse('$_base/creators/$userId/onboarding/dismiss-tajirika'),
      );
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CreatorOnboardingService] dismiss error: $e');
      }
      return false;
    }
  }

  Future<bool> setOffDayMode(int userId, bool enabled) async {
    if (ApiConfig.useGraphqlBackend) {
      return GraphqlCreatorMetricsService.setOffDayMode(enabled);
    }
    try {
      final resp = await http.post(
        Uri.parse('$_base/creators/$userId/onboarding/off-day'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'enabled': enabled}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CreatorOnboardingService] setOffDayMode error: $e');
      }
      return false;
    }
  }
}
