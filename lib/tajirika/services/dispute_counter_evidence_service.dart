import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class DisputeCounterEvidenceService {
  static Future<bool> upload({
    required int disputeId,
    required int partnerUserId,
    required String evidenceType,
    String? description,
    required List<File> files,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/dispute-counter-evidence'),
      );
      request.fields['dispute_id'] = '$disputeId';
      request.fields['partner_user_id'] = '$partnerUserId';
      request.fields['evidence_type'] = evidenceType;
      if (description != null) request.fields['description'] = description;

      for (final f in files) {
        request.files.add(await http.MultipartFile.fromPath('files[]', f.path));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body);
        return body['success'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<CounterEvidenceItem>> list({
    int? disputeId,
    int? partnerUserId,
    int limit = 50,
  }) async {
    try {
      final params = <String, String>{'limit': '$limit'};
      if (disputeId != null) params['dispute_id'] = '$disputeId';
      if (partnerUserId != null) params['partner_user_id'] = '$partnerUserId';
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/dispute-counter-evidence')
            .replace(queryParameters: params),
      );
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body);
      if (body['success'] != true) return const [];
      return ((body['data'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => CounterEvidenceItem.fromJson(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

class CounterEvidenceItem {
  final int id;
  final int disputeId;
  final int partnerUserId;
  final String evidenceType;
  final String? description;
  final List<String> fileUrls;
  final bool isLate;
  final DateTime submittedAt;

  const CounterEvidenceItem({
    required this.id,
    required this.disputeId,
    required this.partnerUserId,
    required this.evidenceType,
    this.description,
    required this.fileUrls,
    required this.isLate,
    required this.submittedAt,
  });

  factory CounterEvidenceItem.fromJson(Map<String, dynamic> j) {
    return CounterEvidenceItem(
      id: j['id'] ?? 0,
      disputeId: j['dispute_id'] ?? 0,
      partnerUserId: j['partner_user_id'] ?? 0,
      evidenceType: j['evidence_type'] ?? '',
      description: j['description']?.toString(),
      fileUrls: (j['files'] as List?)?.whereType<String>().toList() ?? const [],
      isLate: j['is_late'] == true,
      submittedAt: DateTime.tryParse(j['submitted_at'] ?? '') ?? DateTime.now(),
    );
  }
}
