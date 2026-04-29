import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';

/// Spec line 244 — review-image fraud guard. Calls /api/reviews/check-similarity
/// with a public image URL; returns a similarity score 0.0–1.0 + flagged bool.
/// Score >= 0.92 means the image looks like a copy of an existing review's photo.
class ImageSimilarityResult {
  final double score;
  final bool flagged;
  final String method;
  ImageSimilarityResult({
    required this.score,
    required this.flagged,
    required this.method,
  });

  factory ImageSimilarityResult.fromJson(Map<String, dynamic> json) {
    return ImageSimilarityResult(
      score: () {
        final v = json['score'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      }(),
      flagged: json['flagged'] == true,
      method: json['method']?.toString() ?? 'unknown',
    );
  }
}

class ImageSimilarityService {
  static Future<ImageSimilarityResult?> check({
    required String imageUrl,
    int? reviewId,
  }) async {
    final body = <String, dynamic>{'image_url': imageUrl};
    if (reviewId != null) body['review_id'] = reviewId;
    try {
      final res = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/reviews/check-similarity'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      final r = jsonDecode(res.body);
      if (r['success'] != true) return null;
      return ImageSimilarityResult.fromJson(r.cast<String, dynamic>());
    } catch (e) {
      debugPrint('[ImageSimilarityService] error: $e');
      return null;
    }
  }
}
