// Models for collaboration radar suggestions.

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// A suggested collaboration between two creators.
class CollaborationSuggestion {
  final int id;
  final int creatorAId;
  final int creatorBId;
  final String sharedCategory;
  final double affinityScore;
  final String status; // suggested, accepted, dismissed
  final String? partnerName;
  final String? partnerAvatarUrl;
  final String? partnerTier;
  final int? partnerFollowerCount;

  CollaborationSuggestion({
    required this.id,
    required this.creatorAId,
    required this.creatorBId,
    required this.sharedCategory,
    required this.affinityScore,
    required this.status,
    this.partnerName,
    this.partnerAvatarUrl,
    this.partnerTier,
    this.partnerFollowerCount,
  });

  factory CollaborationSuggestion.fromJson(Map<String, dynamic> json) {
    return CollaborationSuggestion(
      id: _parseInt(json['id']),
      creatorAId: _parseInt(json['creator_a_id']),
      creatorBId: _parseInt(json['creator_b_id']),
      sharedCategory: (json['shared_category'] as String?) ?? '',
      affinityScore: _parseDouble(json['affinity_score']),
      status: (json['status'] as String?) ?? 'suggested',
      partnerName: json['partner_name'] as String?,
      partnerAvatarUrl: json['partner_avatar_url'] as String?,
      partnerTier: json['partner_tier'] as String?,
      partnerFollowerCount: json['partner_follower_count'] != null
          ? _parseInt(json['partner_follower_count']) : null,
    );
  }
}
