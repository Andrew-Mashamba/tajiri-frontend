// lib/pharmacy/models/pharmacy_models.dart
import 'package:flutter/material.dart';

// ─── Medicine / Product ─────────────────────────────────────────

class Medicine {
  final int id;
  final String name;
  final String? genericName;
  final String? brand;
  final String dosageForm; // tablet, capsule, syrup, injection, cream, drops
  final String strength; // e.g. "500mg", "250mg/5ml"
  final double price;
  final bool inStock;
  final bool prescriptionRequired;
  final String? category;
  final String? imageUrl;
  final String? description;

  Medicine({
    required this.id,
    required this.name,
    this.genericName,
    this.brand,
    required this.dosageForm,
    required this.strength,
    required this.price,
    this.inStock = true,
    this.prescriptionRequired = false,
    this.category,
    this.imageUrl,
    this.description,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      genericName: json['generic_name'],
      brand: json['brand'],
      dosageForm: json['dosage_form'] ?? 'tablet',
      strength: json['strength'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      inStock: json['in_stock'] ?? true,
      prescriptionRequired: json['prescription_required'] ?? false,
      category: json['category'],
      imageUrl: json['image_url'],
      description: json['description'],
    );
  }

  String get dosageFormLabel {
    switch (dosageForm) {
      case 'tablet': return 'Tembe';
      case 'capsule': return 'Kapusuli';
      case 'syrup': return 'Maji';
      case 'injection': return 'Sindano';
      case 'cream': return 'Krimu';
      case 'drops': return 'Matone';
      case 'inhaler': return 'Kivutio';
      default: return dosageForm;
    }
  }

  IconData get dosageIcon {
    switch (dosageForm) {
      case 'tablet':
      case 'capsule': return Icons.medication_rounded;
      case 'syrup': return Icons.local_drink_rounded;
      case 'injection': return Icons.vaccines_rounded;
      case 'cream': return Icons.spa_rounded;
      case 'drops': return Icons.water_drop_rounded;
      case 'inhaler': return Icons.air_rounded;
      default: return Icons.medication_rounded;
    }
  }
}

// ─── Orders ─────────────────────────────────────────────────────

enum PharmacyOrderStatus {
  awaitingPayment,
  pending,
  confirmed,
  preparing,
  readyForPickup,
  outForDelivery,
  delivered,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case PharmacyOrderStatus.awaitingPayment: return 'Inasubiri Malipo';
      case PharmacyOrderStatus.pending: return 'Inasubiri';
      case PharmacyOrderStatus.confirmed: return 'Imethibitishwa';
      case PharmacyOrderStatus.preparing: return 'Inaandaliwa';
      case PharmacyOrderStatus.readyForPickup: return 'Tayari Kuchukuliwa';
      case PharmacyOrderStatus.outForDelivery: return 'Inasafirishwa';
      case PharmacyOrderStatus.delivered: return 'Imetolewa';
      case PharmacyOrderStatus.completed: return 'Imekamilika';
      case PharmacyOrderStatus.cancelled: return 'Imeghairiwa';
    }
  }

  Color get color {
    switch (this) {
      case PharmacyOrderStatus.awaitingPayment: return Colors.blue;
      case PharmacyOrderStatus.pending: return Colors.orange;
      case PharmacyOrderStatus.confirmed:
      case PharmacyOrderStatus.preparing: return Colors.blue;
      case PharmacyOrderStatus.readyForPickup: return Colors.teal;
      case PharmacyOrderStatus.outForDelivery: return Colors.deepPurple;
      case PharmacyOrderStatus.delivered:
      case PharmacyOrderStatus.completed: return const Color(0xFF4CAF50);
      case PharmacyOrderStatus.cancelled: return Colors.red;
    }
  }

  static PharmacyOrderStatus fromString(String? s) {
    switch (s) {
      case 'awaiting_payment': return PharmacyOrderStatus.awaitingPayment;
      case 'pending': return PharmacyOrderStatus.pending;
      case 'confirmed': return PharmacyOrderStatus.confirmed;
      case 'preparing': return PharmacyOrderStatus.preparing;
      case 'ready_for_pickup': return PharmacyOrderStatus.readyForPickup;
      case 'out_for_delivery': return PharmacyOrderStatus.outForDelivery;
      case 'delivered': return PharmacyOrderStatus.delivered;
      case 'completed': return PharmacyOrderStatus.completed;
      case 'cancelled': return PharmacyOrderStatus.cancelled;
      default: return PharmacyOrderStatus.pending;
    }
  }
}

class PharmacyOrder {
  final int id;
  final String orderId;
  final int userId;
  final int pharmacyId;
  final String? pharmacyName;
  final int? doctorId;
  final String? doctorName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final PharmacyOrderStatus status;
  final bool isDelivery;
  final String? deliveryAddress;
  final int? prescriptionId;
  final DateTime createdAt;
  final DateTime? estimatedReadyAt;

  PharmacyOrder({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.pharmacyId,
    this.pharmacyName,
    this.doctorId,
    this.doctorName,
    this.items = const [],
    required this.subtotal,
    this.deliveryFee = 0,
    required this.totalAmount,
    required this.status,
    this.isDelivery = false,
    this.deliveryAddress,
    this.prescriptionId,
    required this.createdAt,
    this.estimatedReadyAt,
  });

  factory PharmacyOrder.fromJson(Map<String, dynamic> json) {
    return PharmacyOrder(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      userId: json['user_id'] ?? 0,
      pharmacyId: json['pharmacy_id'] ?? 0,
      pharmacyName: json['pharmacy_name'],
      doctorId: (json['doctor_id'] as num?)?.toInt(),
      doctorName: json['doctor_name'],
      items: (json['items'] as List?)
              ?.map((i) => OrderItem.fromJson(i))
              .toList() ??
          [],
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: PharmacyOrderStatus.fromString(json['status']),
      isDelivery: json['is_delivery'] ?? false,
      deliveryAddress: json['delivery_address'],
      prescriptionId: (json['prescription_id'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      estimatedReadyAt: json['estimated_ready_at'] != null ? DateTime.tryParse(json['estimated_ready_at']) : null,
    );
  }

  bool get isActive => [
        PharmacyOrderStatus.awaitingPayment,
        PharmacyOrderStatus.pending,
        PharmacyOrderStatus.confirmed,
        PharmacyOrderStatus.preparing,
        PharmacyOrderStatus.readyForPickup,
        PharmacyOrderStatus.outForDelivery,
      ].contains(status);
  bool get isDoctorPrescribed => doctorId != null;
}

class OrderItem {
  final int medicineId;
  final String medicineName;
  final String strength;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItem({
    required this.medicineId,
    required this.medicineName,
    required this.strength,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      medicineId: json['medicine_id'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      strength: json['strength'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Result wrappers ────────────────────────────────────────────

class PharmacyResult<T> {
  final bool success;
  final T? data;
  final String? message;
  PharmacyResult({required this.success, this.data, this.message});
}

class PharmacyListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  PharmacyListResult({required this.success, this.items = const [], this.message});
}
