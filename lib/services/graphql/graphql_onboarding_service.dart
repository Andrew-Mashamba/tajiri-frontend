import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
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

  // ── Profile photo (post-register; media upload needs an auth token) ───────
  /// Uploads the avatar file to the media endpoint and returns its file_path.
  static Future<String?> uploadAvatar(String filePath, String accessToken) async {
    try {
      final req = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.graphqlMediaUploadUrl),
      );
      req.headers['Authorization'] = 'Bearer $accessToken';
      req.fields['media_type'] = 'image';
      req.files.add(await http.MultipartFile.fromPath('file', filePath));
      final streamed = await req.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return (data['data'] as Map<String, dynamic>)['file_path'] as String?;
        }
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlOnboardingService] uploadAvatar: $e');
      return null;
    }
  }

  static Future<bool> setProfilePhoto(String path) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        r'mutation($p: String!){ setProfilePhoto(path: $p){ id avatarUrl } }',
        variables: {'p': path},
        auth: true,
      );
      return data['setProfilePhoto'] != null;
    } catch (e) {
      if (kDebugMode) debugPrint('[GraphqlOnboardingService] setProfilePhoto: $e');
      return false;
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

  // ── Detailed pickers: a-level combinations + university tree ──────────────
  static const _combinationFields = r'id code name category subjects careers';

  static Future<List<Map<String, dynamic>>> alevelCombinations() async {
    final data = await TajiriGraphqlClient.instance.query(
      '{ alevelCombinations { $_combinationFields } }');
    return (data['alevelCombinations'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> schoolCombinations(String institutionId) async {
    final data = await TajiriGraphqlClient.instance.query(
      'query(\$s: ID!){ schoolCombinations(institutionId: \$s){ $_combinationFields } }',
      variables: {'s': institutionId});
    return (data['schoolCombinations'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> universityColleges(String universityId) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'query($u: ID!){ universityColleges(universityId: $u){ id code name } }',
      variables: {'u': universityId});
    return (data['universityColleges'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> collegeDepartments(String collegeId) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'query($c: ID!){ collegeDepartments(collegeId: $c){ id code name } }',
      variables: {'c': collegeId});
    return (data['collegeDepartments'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> departmentProgrammes(String departmentId) async {
    final data = await TajiriGraphqlClient.instance.query(
      r'query($d: ID!){ departmentProgrammes(departmentId: $d){ id code name level duration } }',
      variables: {'d': departmentId});
    return (data['departmentProgrammes'] as List? ?? []).cast<Map<String, dynamic>>();
  }
}
