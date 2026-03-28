import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/battle_models.dart';

String get _baseUrl => ApiConfig.baseUrl;

class BattleService {
  Future<List<CreatorBattle>> getActiveBattles({required String token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/creator-battles'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawList = data['data'] is List ? data['data'] as List : [];
        return rawList.whereType<Map<String, dynamic>>()
            .map((e) => CreatorBattle.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[BattleService] getActiveBattles error: $e');
      return [];
    }
  }

  Future<CreatorBattle?> getBattle({required String token, required int battleId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/battles/$battleId'),
        headers: ApiConfig.authHeaders(token),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] is Map<String, dynamic>) {
          return CreatorBattle.fromJson(data['data'] as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint('[BattleService] getBattle error: $e');
      return null;
    }
  }

  Future<bool> vote({
    required String token,
    required int battleId,
    required String side, // 'a' or 'b'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/battles/$battleId/vote'),
        headers: {...ApiConfig.authHeaders(token), 'Content-Type': 'application/json'},
        body: jsonEncode({'side': side}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[BattleService] vote error: $e');
      return false;
    }
  }
}
