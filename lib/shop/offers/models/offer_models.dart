import 'package:intl/intl.dart';

enum OfferStatus {
  pending,
  accepted,
  declined,
  countered,
  expired,
  withdrawn;

  static OfferStatus fromString(String s) {
    switch (s) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'declined':
        return OfferStatus.declined;
      case 'countered':
        return OfferStatus.countered;
      case 'expired':
        return OfferStatus.expired;
      case 'withdrawn':
        return OfferStatus.withdrawn;
      default:
        return OfferStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OfferStatus.pending:
        return 'Pending';
      case OfferStatus.accepted:
        return 'Accepted';
      case OfferStatus.declined:
        return 'Declined';
      case OfferStatus.countered:
        return 'Counter Offer';
      case OfferStatus.expired:
        return 'Expired';
      case OfferStatus.withdrawn:
        return 'Withdrawn';
    }
  }
}

final _tzsFmt = NumberFormat('#,##0', 'en_US');

class ProductOffer {
  final int id;
  final int productId;
  final String productTitle;
  final String productThumbnail;
  final int buyerId;
  final int sellerId;
  final OfferBuyer? buyer;
  final double offeredPrice;
  final double? counterPrice;
  final double originalPrice;
  final OfferStatus status;
  final String? buyerMessage;
  final String? sellerMessage;
  final DateTime expiresAt;
  final DateTime createdAt;
  final int? orderId;
  final double savingsAmount;
  final double savingsPercent;

  const ProductOffer({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.productThumbnail,
    required this.buyerId,
    required this.sellerId,
    this.buyer,
    required this.offeredPrice,
    this.counterPrice,
    required this.originalPrice,
    required this.status,
    this.buyerMessage,
    this.sellerMessage,
    required this.expiresAt,
    required this.createdAt,
    this.orderId,
    required this.savingsAmount,
    required this.savingsPercent,
  });

  factory ProductOffer.fromJson(Map<String, dynamic> json) {
    return ProductOffer(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      productTitle: (json['product_title'] as String?) ?? '',
      productThumbnail: (json['product_thumbnail'] as String?) ?? '',
      buyerId: _parseInt(json['buyer_id']),
      sellerId: _parseInt(json['seller_id']),
      buyer: json['buyer'] != null
          ? OfferBuyer.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      offeredPrice: _parseDouble(json['offered_price']),
      counterPrice: json['counter_price'] != null ? _parseDouble(json['counter_price']) : null,
      originalPrice: _parseDouble(json['original_price']),
      status: OfferStatus.fromString((json['status'] as String?) ?? 'pending'),
      buyerMessage: json['buyer_message'] as String?,
      sellerMessage: json['seller_message'] as String?,
      expiresAt: _parseDateTime(json['expires_at']),
      createdAt: _parseDateTime(json['created_at']),
      orderId: json['order_id'] != null ? _parseInt(json['order_id']) : null,
      savingsAmount: _parseDouble(json['savings_amount']),
      savingsPercent: _parseDouble(json['savings_percent']),
    );
  }

  bool get isActive =>
      (status == OfferStatus.pending || status == OfferStatus.countered) &&
      expiresAt.isAfter(DateTime.now());

  int get hoursUntilExpiry {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inHours.clamp(0, 999);
  }

  String get formattedOfferedPrice => 'TZS ${_tzsFmt.format(offeredPrice)}';
  String get formattedCounterPrice =>
      counterPrice != null ? 'TZS ${_tzsFmt.format(counterPrice!)}' : '';
  String get formattedOriginalPrice => 'TZS ${_tzsFmt.format(originalPrice)}';
  String get formattedSavings => 'TZS ${_tzsFmt.format(savingsAmount)}';

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

class OfferBuyer {
  final int id;
  final String name;
  final String username;
  final String? profileImage;

  const OfferBuyer({
    required this.id,
    required this.name,
    required this.username,
    this.profileImage,
  });

  factory OfferBuyer.fromJson(Map<String, dynamic> json) {
    return OfferBuyer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      profileImage: json['profile_image'] as String?,
    );
  }

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
