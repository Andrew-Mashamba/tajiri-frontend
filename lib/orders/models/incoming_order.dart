// lib/orders/models/incoming_order.dart
//
// Receiver-side view of a purchase order — includes buyer identity (individual
// or business) and which of the user's businesses the order was placed with.
import 'dart:convert';

import '../../config/api_config.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

double _parseDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

class IncomingOrderLine {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  IncomingOrderLine({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory IncomingOrderLine.fromJson(Map<String, dynamic> json) =>
      IncomingOrderLine(
        description: json['description']?.toString() ?? '',
        quantity: _parseDouble(json['quantity']),
        unitPrice: _parseDouble(json['unit_price']),
        totalPrice: _parseDouble(json['total_price']),
      );
}

enum OrderStatus { draft, submitted, accepted, rejected, shipped, delivered, cancelled }

OrderStatus _parseStatus(dynamic v) {
  switch (v?.toString().toLowerCase()) {
    // Buyer-side uses 'sent'; supplier-side uses 'submitted'. Same semantic
    // state (just-dispatched, awaiting supplier action) — collapse to one.
    case 'sent':
    case 'submitted': return OrderStatus.submitted;
    case 'accepted': return OrderStatus.accepted;
    case 'rejected': return OrderStatus.rejected;
    case 'shipped': return OrderStatus.shipped;
    case 'delivered': return OrderStatus.delivered;
    case 'cancelled':
    case 'canceled': return OrderStatus.cancelled;
    default: return OrderStatus.draft;
  }
}

extension OrderStatusX on OrderStatus {
  String get wire {
    switch (this) {
      case OrderStatus.draft: return 'draft';
      case OrderStatus.submitted: return 'submitted';
      case OrderStatus.accepted: return 'accepted';
      case OrderStatus.rejected: return 'rejected';
      case OrderStatus.shipped: return 'shipped';
      case OrderStatus.delivered: return 'delivered';
      case OrderStatus.cancelled: return 'cancelled';
    }
  }
}

class IncomingOrder {
  final int id;
  final String poNumber;
  final OrderStatus status;
  final List<IncomingOrderLine> items;
  final double subtotal;
  final double vatAmount;
  final double totalAmount;
  final DateTime? expectedDeliveryDate;
  final String? notes;
  final DateTime? createdAt;
  final String? rejectionReason;

  // Receiving business (one of the viewer's owned businesses).
  final int receivingBusinessId;
  final String receivingBusinessName;
  final String? receivingBusinessLogoUrl;

  // Buyer identity.
  final String buyerType; // 'individual' | 'business'
  final int? buyerUserId;
  final String? buyerBusinessName;
  final String? buyerBusinessLogoUrl;
  final String? buyerFirstName;
  final String? buyerLastName;
  final String? buyerUsername;
  final String? buyerPhone;
  final String? buyerPhotoUrl;

  IncomingOrder({
    required this.id,
    required this.poNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.vatAmount,
    required this.totalAmount,
    required this.receivingBusinessId,
    required this.receivingBusinessName,
    this.receivingBusinessLogoUrl,
    required this.buyerType,
    this.buyerUserId,
    this.buyerBusinessName,
    this.buyerBusinessLogoUrl,
    this.buyerFirstName,
    this.buyerLastName,
    this.buyerUsername,
    this.buyerPhone,
    this.buyerPhotoUrl,
    this.expectedDeliveryDate,
    this.notes,
    this.createdAt,
    this.rejectionReason,
  });

  String get buyerDisplayName {
    if (buyerType == 'business' && (buyerBusinessName?.isNotEmpty ?? false)) {
      return buyerBusinessName!;
    }
    final first = buyerFirstName ?? '';
    final last = buyerLastName ?? '';
    final full = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (full.isNotEmpty) return full;
    if (buyerUsername?.isNotEmpty ?? false) return '@$buyerUsername';
    return 'Unknown buyer';
  }

  String? get buyerAvatarUrl {
    if (buyerType == 'business') return buyerBusinessLogoUrl;
    return buyerPhotoUrl;
  }

  factory IncomingOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<dynamic> parsedItems;
    if (rawItems is List) {
      parsedItems = rawItems;
    } else if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        parsedItems = decoded is List ? decoded : const [];
      } catch (_) {
        parsedItems = const [];
      }
    } else {
      parsedItems = const [];
    }

    String? photoUrl;
    final rawPhoto = json['buyer_photo_path']?.toString();
    if (rawPhoto != null && rawPhoto.isNotEmpty) {
      photoUrl = rawPhoto.startsWith('http')
          ? ApiConfig.sanitizeUrl(rawPhoto)
          : ApiConfig.sanitizeUrl(
              '${ApiConfig.storageUrl}${ApiConfig.storageUrl.endsWith('/') ? '' : '/'}${rawPhoto.startsWith('/') ? rawPhoto.substring(1) : rawPhoto}');
    }

    return IncomingOrder(
      id: _parseInt(json['id']) ?? 0,
      poNumber: json['po_number']?.toString() ?? '',
      status: _parseStatus(json['status']),
      items: parsedItems
          .whereType<Map>()
          .map((e) => IncomingOrderLine.fromJson(e.cast<String, dynamic>()))
          .toList(),
      subtotal: _parseDouble(json['subtotal']),
      vatAmount: _parseDouble(json['vat_amount']),
      totalAmount: _parseDouble(json['total_amount']),
      receivingBusinessId: _parseInt(json['receiving_business_id']) ?? 0,
      receivingBusinessName:
          json['receiving_business_name']?.toString() ?? '',
      receivingBusinessLogoUrl: ApiConfig.sanitizeUrl(
          json['receiving_business_logo_url']?.toString()),
      buyerType: json['buyer_type']?.toString() ?? 'business',
      buyerUserId: _parseInt(json['buyer_user_id']),
      buyerBusinessName: json['buyer_business_name']?.toString(),
      buyerBusinessLogoUrl: ApiConfig.sanitizeUrl(
          json['buyer_business_logo_url']?.toString()),
      buyerFirstName: json['buyer_first_name']?.toString(),
      buyerLastName: json['buyer_last_name']?.toString(),
      buyerUsername: json['buyer_username']?.toString(),
      buyerPhone: json['buyer_phone']?.toString(),
      buyerPhotoUrl: photoUrl,
      expectedDeliveryDate: _parseDate(json['expected_delivery_date']),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['created_at']),
      rejectionReason: json['rejection_reason']?.toString(),
    );
  }
}
