import 'package:flutter/foundation.dart';

import 'tajiri_graphql_client.dart';

/// GraphQL onboarding (phone-OTP registration journey) against TAJIRI-BACKEND.
/// Replaces the old REST /users/register + /check-phone + mock OTP.
class GraphqlOnboardingService {
  // ── Phone step ──────────────────────────────────────────────────────────
  static Future<bool> checkMsisdnAvailable(String msisdn) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'query($m: String!){ checkMsisdnAvailable(msisdn: $m) }',
      variables: {'m': msisdn},
    );
    return data['checkMsisdnAvailable'] == true;
  }

  /// Sends an OTP. Returns the dev code in dev mode (no SMS gateway), else null.
  static Future<({int expiresIn, String? devCode})> requestOtp(String msisdn) async {
    final data = await TajiriGraphqlClient.instance.mutate(
      r'mutation($m: String!){ requestOtp(msisdn: $m){ expiresIn devCode } }',
      variables: {'m': msisdn},
    );
    final r = data['requestOtp'] as Map<String, dynamic>? ?? {};
    return (expiresIn: (r['expiresIn'] as int?) ?? 0, devCode: r['devCode'] as String?);
  }

  /// Verifies the OTP and returns a short-lived signup token for registerAccount.
  static Future<({bool success, String? signupToken, String? error})> verifyOtp(
    String msisdn,
    String code,
  ) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'mutation($m: String!, $c: String!){ verifyOtp(msisdn: $m, code: $c){ signupToken } }',
        variables: {'m': msisdn, 'c': code},
      );
      final token = (data['verifyOtp'] as Map<String, dynamic>?)?['signupToken'] as String?;
      return (success: token != null, signupToken: token, error: null);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlOnboardingService] verifyOtp: $e');
      return (success: false, signupToken: null, error: '$e');
    }
  }

  // ── Completion ──────────────────────────────────────────────────────────
  static const _registerMutation = r'''
    mutation RegisterAccount($input: RegisterAccountInput!) {
      registerAccount(input: $input) {
        accessToken
        refreshToken
        accessExpiresIn
        refreshExpiresIn
        user { id username displayName avatarUrl msisdn }
      }
    }
  ''';

  static Future<({bool success, Map<String, dynamic>? payload, String? error})>
      registerAccount(Map<String, dynamic> input) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        _registerMutation,
        variables: {'input': input},
      );
      final payload = data['registerAccount'] as Map<String, dynamic>?;
      if (payload == null) {
        return (success: false, payload: null, error: 'Usajili umeshindwa');
      }
      return (success: true, payload: payload, error: null);
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlOnboardingService] registerAccount: $e');
      return (success: false, payload: null, error: '$e');
    }
  }

  // ── Reference-data pickers ────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> regions() async {
    final data = await TajiriGraphqlClient.instance.query(
      r'{ regions { id name postCode } }',
    );
    return (data['regions'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> locationChildren(String parentId) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'query($p: ID!){ locationChildren(parentId: $p){ id name level postCode streets } }',
      variables: {'p': parentId},
    );
    return (data['locationChildren'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  /// level in: primary | secondary | alevel | postsecondary | university
  static Future<List<Map<String, dynamic>>> searchInstitutions({
    required String level,
    String? query,
    String? regionCode,
    int limit = 20,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'''query($l: String!, $q: String, $rc: String, $n: Int!){
        searchInstitutions(level: $l, q: $q, regionCode: $rc, limit: $n){
          id name code regionCode regionName districtName type category
        }
      }''',
      variables: {'l': level, 'q': query, 'rc': regionCode, 'n': limit},
    );
    return (data['searchInstitutions'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> searchBusinesses({
    String? query,
    String? sector,
    int limit = 20,
  }) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'''query($q: String, $s: String, $n: Int!){
        searchBusinesses(q: $q, sector: $s, limit: $n){ id name sector ownership region }
      }''',
      variables: {'q': query, 's': sector, 'n': limit},
    );
    return (data['searchBusinesses'] as List? ?? []).cast<Map<String, dynamic>>();
  }
}
