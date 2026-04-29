import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../models/peer_endorsement.dart';

void _log(String m) => debugPrint('[PeerEndorsementService] $m');

class PeerEndorsementService {
  static Future<List<PeerEndorsement>> listForUser(int endorseeUserId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/peer-endorsements')
        .replace(queryParameters: {'endorsee_user_id': '$endorseeUserId'});
    try {
      final res = await http.get(uri);
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => PeerEndorsement.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (e) {
      _log('list error: $e');
      return const [];
    }
  }

  static Future<bool> create({
    required int endorseeUserId,
    required int endorserUserId,
    required String skillCategory,
    String? comment,
  }) async {
    try {
      final body = <String, dynamic>{
        'endorsee_user_id': endorseeUserId,
        'endorser_user_id': endorserUserId,
        'skill_category': skillCategory,
      };
      if (comment != null && comment.isNotEmpty) body['comment'] = comment;
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/peer-endorsements'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final r = jsonDecode(res.body);
      return res.statusCode >= 200 && res.statusCode < 300 && r['success'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> delete(int id) async {
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/peer-endorsements/$id'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
