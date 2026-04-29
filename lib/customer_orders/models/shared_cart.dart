int? _i(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _d(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class SharedCart {
  final int id;
  final String token;
  final int ownerUserId;
  final int? partnerId;
  final int totalTzs;
  final String status; // open|settled|cancelled
  final DateTime? settledAt;
  final DateTime? createdAt;

  SharedCart({
    required this.id,
    required this.token,
    required this.ownerUserId,
    required this.partnerId,
    required this.totalTzs,
    required this.status,
    required this.settledAt,
    required this.createdAt,
  });

  factory SharedCart.fromJson(Map<String, dynamic> json) {
    return SharedCart(
      id: _i(json['id']) ?? 0,
      token: json['token']?.toString() ?? '',
      ownerUserId: _i(json['owner_user_id']) ?? 0,
      partnerId: _i(json['partner_id']),
      totalTzs: _i(json['total_tzs']) ?? 0,
      status: json['status']?.toString() ?? 'open',
      settledAt: _d(json['settled_at']),
      createdAt: _d(json['created_at']),
    );
  }

  String get shareUrl => 'https://tajiri.zimasystems.com/c/$token';
}

class SharedCartItem {
  final int id;
  final int sharedCartId;
  final int userId;
  final int partnerProductId;
  final int quantity;
  final int unitPriceTzs;
  final String? notes;
  final String? userName;
  final String? productTitle;

  SharedCartItem({
    required this.id,
    required this.sharedCartId,
    required this.userId,
    required this.partnerProductId,
    required this.quantity,
    required this.unitPriceTzs,
    required this.notes,
    required this.userName,
    required this.productTitle,
  });

  int get lineTotal => quantity * unitPriceTzs;

  factory SharedCartItem.fromJson(Map<String, dynamic> json) {
    return SharedCartItem(
      id: _i(json['id']) ?? 0,
      sharedCartId: _i(json['shared_cart_id']) ?? 0,
      userId: _i(json['user_id']) ?? 0,
      partnerProductId: _i(json['partner_product_id']) ?? 0,
      quantity: _i(json['quantity']) ?? 1,
      unitPriceTzs: _i(json['unit_price_tzs']) ?? _i(json['base_price_tzs']) ?? 0,
      notes: json['notes']?.toString(),
      userName: json['user_name']?.toString(),
      productTitle: json['product_title']?.toString(),
    );
  }
}
