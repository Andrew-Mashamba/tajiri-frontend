import 'package:flutter/material.dart';
import '../../config/api_config.dart';

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  return int.tryParse(v.toString());
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

enum ServicePricingType {
  fixed,
  hourly,
  quoted;

  static ServicePricingType fromString(String? s) {
    switch (s) {
      case 'hourly': return ServicePricingType.hourly;
      case 'quoted': return ServicePricingType.quoted;
      default: return ServicePricingType.fixed;
    }
  }

  String get value => name;

  String label(bool isSwahili) {
    switch (this) {
      case ServicePricingType.fixed: return isSwahili ? 'Bei ya kawaida' : 'Fixed';
      case ServicePricingType.hourly: return isSwahili ? 'Kwa saa' : 'Per hour';
      case ServicePricingType.quoted: return isSwahili ? 'Bei ya makubaliano' : 'Quote only';
    }
  }
}

enum ServiceAvailability {
  available,
  unavailable,
  byRequest;

  static ServiceAvailability fromString(String? s) {
    switch (s) {
      case 'unavailable': return ServiceAvailability.unavailable;
      case 'by_request': return ServiceAvailability.byRequest;
      default: return ServiceAvailability.available;
    }
  }

  String get value {
    switch (this) {
      case ServiceAvailability.byRequest: return 'by_request';
      default: return name;
    }
  }

  String label(bool isSwahili) {
    switch (this) {
      case ServiceAvailability.available: return isSwahili ? 'Inapatikana' : 'Available';
      case ServiceAvailability.unavailable: return isSwahili ? 'Haipatikani' : 'Unavailable';
      case ServiceAvailability.byRequest: return isSwahili ? 'Kwa ombi' : 'By request';
    }
  }

  Color get color {
    switch (this) {
      case ServiceAvailability.available: return const Color(0xFF4CAF50);
      case ServiceAvailability.unavailable: return const Color(0xFF9E9E9E);
      case ServiceAvailability.byRequest: return const Color(0xFFFF9800);
    }
  }
}

class BusinessService {
  final int id;
  final int businessId;
  final String name;
  final String? description;
  final ServicePricingType pricingType;
  final double? price;
  final String currency;
  final String? photoUrl;
  final int? durationMinutes;
  final ServiceAvailability availability;
  final int? shopCategoryId;
  final String? category;
  final bool isActive;
  final int inquiryCount;
  final DateTime? lastInquiryAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusinessService({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.pricingType = ServicePricingType.fixed,
    this.price,
    this.currency = 'TZS',
    this.photoUrl,
    this.durationMinutes,
    this.availability = ServiceAvailability.available,
    this.shopCategoryId,
    this.category,
    this.isActive = true,
    this.inquiryCount = 0,
    this.lastInquiryAt,
    this.createdAt,
    this.updatedAt,
  });

  factory BusinessService.fromJson(Map<String, dynamic> json) {
    return BusinessService(
      id: _parseInt(json['id']) ?? 0,
      businessId: _parseInt(json['user_business_id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pricingType: ServicePricingType.fromString(json['pricing_type']?.toString()),
      price: _parseDouble(json['price']),
      currency: json['currency']?.toString() ?? 'TZS',
      photoUrl: json['photo_url'] != null
          ? ApiConfig.sanitizeUrl(json['photo_url'].toString())
          : null,
      durationMinutes: _parseInt(json['duration_minutes']),
      availability: ServiceAvailability.fromString(json['availability']?.toString()),
      shopCategoryId: _parseInt(json['shop_category_id']),
      category: json['category']?.toString(),
      isActive: json['is_active'] == true,
      inquiryCount: _parseInt(json['inquiry_count']) ?? 0,
      lastInquiryAt: json['last_inquiry_at'] != null
          ? DateTime.tryParse(json['last_inquiry_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  String priceBadge(bool isSwahili) {
    if (pricingType == ServicePricingType.quoted || price == null) {
      return isSwahili ? 'Bei ya makubaliano' : 'Quote only';
    }
    final formatted = _fmtPrice(price!);
    return pricingType == ServicePricingType.hourly
        ? 'TZS $formatted/hr'
        : 'TZS $formatted';
  }

  static String _fmtPrice(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
