// lib/bills/models/bills_models.dart
import 'package:flutter/material.dart';

// ─── Bill Type ─────────────────────────────────────────────────

enum BillType {
  electricity,
  water,
  airtime,
  tv,
  internet;

  String get displayName {
    switch (this) {
      case BillType.electricity: return 'LUKU / Umeme';
      case BillType.water: return 'Maji / DAWASCO';
      case BillType.airtime: return 'Vocha';
      case BillType.tv: return 'TV';
      case BillType.internet: return 'Intaneti';
    }
  }

  String get subtitle {
    switch (this) {
      case BillType.electricity: return 'Electricity';
      case BillType.water: return 'Water';
      case BillType.airtime: return 'Airtime';
      case BillType.tv: return 'TV Subscription';
      case BillType.internet: return 'Internet';
    }
  }

  IconData get icon {
    switch (this) {
      case BillType.electricity: return Icons.bolt_rounded;
      case BillType.water: return Icons.water_drop_rounded;
      case BillType.airtime: return Icons.phone_android_rounded;
      case BillType.tv: return Icons.tv_rounded;
      case BillType.internet: return Icons.wifi_rounded;
    }
  }

  static BillType fromString(String? s) {
    return BillType.values.firstWhere(
      (v) => v.name == s,
      orElse: () => BillType.electricity,
    );
  }
}

// ─── Mobile Operator ───────────────────────────────────────────

enum MobileOperator {
  vodacom,
  airtel,
  tigo,
  halotel;

  String get displayName {
    switch (this) {
      case MobileOperator.vodacom: return 'Vodacom';
      case MobileOperator.airtel: return 'Airtel';
      case MobileOperator.tigo: return 'Tigo';
      case MobileOperator.halotel: return 'Halotel';
    }
  }

  String get prefix {
    switch (this) {
      case MobileOperator.vodacom: return '075, 076';
      case MobileOperator.airtel: return '078, 068';
      case MobileOperator.tigo: return '071, 065';
      case MobileOperator.halotel: return '062';
    }
  }

  static MobileOperator fromString(String? s) {
    return MobileOperator.values.firstWhere(
      (v) => v.name == s,
      orElse: () => MobileOperator.vodacom,
    );
  }
}

// ─── TV Provider ───────────────────────────────────────────────

enum TvProvider {
  dstv,
  azam,
  startimes;

  String get displayName {
    switch (this) {
      case TvProvider.dstv: return 'DStv';
      case TvProvider.azam: return 'Azam TV';
      case TvProvider.startimes: return 'StarTimes';
    }
  }

  static TvProvider fromString(String? s) {
    return TvProvider.values.firstWhere(
      (v) => v.name == s,
      orElse: () => TvProvider.dstv,
    );
  }
}

// ─── Payment Status ────────────────────────────────────────────

enum BillPaymentStatus {
  pending,
  success,
  failed;

  String get displayName {
    switch (this) {
      case BillPaymentStatus.pending: return 'Inasubiri';
      case BillPaymentStatus.success: return 'Imefanikiwa';
      case BillPaymentStatus.failed: return 'Imeshindwa';
    }
  }

  Color get color {
    switch (this) {
      case BillPaymentStatus.pending: return Colors.orange;
      case BillPaymentStatus.success: return const Color(0xFF4CAF50);
      case BillPaymentStatus.failed: return Colors.red;
    }
  }

  static BillPaymentStatus fromString(String? s) {
    switch (s) {
      case 'pending': return BillPaymentStatus.pending;
      case 'success': return BillPaymentStatus.success;
      case 'failed': return BillPaymentStatus.failed;
      default: return BillPaymentStatus.pending;
    }
  }
}

// ─── Bill Payment ──────────────────────────────────────────────

class BillPayment {
  final int id;
  final BillType type;
  final String provider;
  final String accountNumber;
  final double amount;
  final String? token;
  final String? reference;
  final BillPaymentStatus status;
  final DateTime date;

  BillPayment({
    required this.id,
    required this.type,
    required this.provider,
    required this.accountNumber,
    required this.amount,
    this.token,
    this.reference,
    required this.status,
    required this.date,
  });

  factory BillPayment.fromJson(Map<String, dynamic> json) {
    return BillPayment(
      id: json['id'] ?? 0,
      type: BillType.fromString(json['type']),
      provider: json['provider'] ?? '',
      accountNumber: json['account_number'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      token: json['token'],
      reference: json['reference'],
      status: BillPaymentStatus.fromString(json['status']),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// ─── Saved Account ─────────────────────────────────────────────

class SavedAccount {
  final int id;
  final BillType type;
  final String label;
  final String accountNumber;
  final String? provider;

  SavedAccount({
    required this.id,
    required this.type,
    required this.label,
    required this.accountNumber,
    this.provider,
  });

  factory SavedAccount.fromJson(Map<String, dynamic> json) {
    return SavedAccount(
      id: json['id'] ?? 0,
      type: BillType.fromString(json['type']),
      label: json['label'] ?? '',
      accountNumber: json['account_number'] ?? '',
      provider: json['provider'],
    );
  }
}

// ─── Result wrappers ───────────────────────────────────────────

class BillsResult<T> {
  final bool success;
  final T? data;
  final String? message;
  BillsResult({required this.success, this.data, this.message});
}

class BillsListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  BillsListResult({required this.success, this.items = const [], this.message});
}
