int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class PeerEndorsement {
  final int id;
  final int endorseeUserId;
  final int endorserUserId;
  final String skillCategory;
  final String? comment;
  final String? endorserName;
  final String? endorserPhotoUrl;
  final DateTime? createdAt;

  PeerEndorsement({
    required this.id,
    required this.endorseeUserId,
    required this.endorserUserId,
    required this.skillCategory,
    required this.comment,
    required this.endorserName,
    required this.endorserPhotoUrl,
    required this.createdAt,
  });

  factory PeerEndorsement.fromJson(Map<String, dynamic> json) {
    return PeerEndorsement(
      id: _parseIntN(json['id']) ?? 0,
      endorseeUserId: _parseIntN(json['endorsee_user_id']) ?? 0,
      endorserUserId: _parseIntN(json['endorser_user_id']) ?? 0,
      skillCategory: json['skill_category']?.toString() ?? '',
      comment: json['comment']?.toString(),
      endorserName: json['endorser_name']?.toString(),
      endorserPhotoUrl: json['endorser_photo']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }
}
