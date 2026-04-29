int? _parseIntN(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _parseBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.toLowerCase();
    return s == 'true' || s == '1';
  }
  return false;
}

class ProductVariant {
  final int id;
  final int partnerProductId;
  final String? labelSw;
  final String? labelEn;
  final int priceTzs;
  final int leadTimeHours;
  final int durationMinutes;
  final int sortOrder;
  final bool isActive;

  ProductVariant({
    required this.id,
    required this.partnerProductId,
    required this.labelSw,
    required this.labelEn,
    required this.priceTzs,
    required this.leadTimeHours,
    required this.durationMinutes,
    required this.sortOrder,
    required this.isActive,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: _parseIntN(json['id']) ?? 0,
      partnerProductId: _parseIntN(json['partner_product_id']) ?? 0,
      labelSw: json['label_sw']?.toString(),
      labelEn: json['label_en']?.toString(),
      priceTzs: _parseIntN(json['price_tzs']) ?? 0,
      leadTimeHours: _parseIntN(json['lead_time_hours']) ?? 0,
      durationMinutes: _parseIntN(json['duration_minutes']) ?? 0,
      sortOrder: _parseIntN(json['sort_order']) ?? 0,
      isActive: _parseBool(json['is_active']),
    );
  }

  String displayLabel(bool isSwahili) {
    final sw = labelSw ?? '';
    final en = labelEn ?? '';
    if (isSwahili && sw.isNotEmpty) return sw;
    if (en.isNotEmpty) return en;
    if (sw.isNotEmpty) return sw;
    return '—';
  }
}
