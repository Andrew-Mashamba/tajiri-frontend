// lib/ewura/models/ewura_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

class SingleResult<T> {
  final bool success;
  final T? data;
  final String? message;
  SingleResult({required this.success, this.data, this.message});
}

class PaginatedResult<T> {
  final bool success;
  final List<T> items;
  final String? message;
  final int currentPage;
  final int lastPage;
  PaginatedResult({
    required this.success,
    this.items = const [],
    this.message,
    this.currentPage = 1,
    this.lastPage = 1,
  });
  bool get hasMore => currentPage < lastPage;
}

// ─── Fuel Price ───────────────────────────────────────────────

class FuelPrice {
  final int id;
  final String region;
  final String fuelType; // petrol, diesel, kerosene
  final double price;
  final DateTime effectiveDate;
  final DateTime? expiryDate;

  FuelPrice({
    required this.id,
    required this.region,
    required this.fuelType,
    required this.price,
    required this.effectiveDate,
    this.expiryDate,
  });

  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      id: _parseInt(json['id']),
      region: json['region'] ?? '',
      fuelType: json['fuel_type'] ?? 'petrol',
      price: _parseDouble(json['price']),
      effectiveDate:
          DateTime.tryParse('${json['effective_date']}') ?? DateTime.now(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse('${json['expiry_date']}')
          : null,
    );
  }
}

// ─── Fuel Station ─────────────────────────────────────────────

class FuelStation {
  final int id;
  final String name;
  final String brand;
  final String address;
  final String region;
  final double? lat;
  final double? lng;
  final double? distance;
  final bool hasShop;
  final bool hasCarWash;

  FuelStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.region,
    this.lat,
    this.lng,
    this.distance,
    required this.hasShop,
    required this.hasCarWash,
  });

  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: _parseInt(json['id']),
      name: json['name'] ?? '',
      brand: json['brand'] ?? '',
      address: json['address'] ?? '',
      region: json['region'] ?? '',
      lat: json['lat'] != null ? _parseDouble(json['lat']) : null,
      lng: json['lng'] != null ? _parseDouble(json['lng']) : null,
      distance:
          json['distance'] != null ? _parseDouble(json['distance']) : null,
      hasShop: json['has_shop'] == true,
      hasCarWash: json['has_car_wash'] == true,
    );
  }
}

// ─── Utility Tariff ───────────────────────────────────────────

class UtilityTariff {
  final int id;
  final String utilityType; // electricity, water, gas
  final String category; // residential, commercial, industrial
  final double ratePerUnit;
  final String unit;
  final double? minCharge;

  UtilityTariff({
    required this.id,
    required this.utilityType,
    required this.category,
    required this.ratePerUnit,
    required this.unit,
    this.minCharge,
  });

  factory UtilityTariff.fromJson(Map<String, dynamic> json) {
    return UtilityTariff(
      id: _parseInt(json['id']),
      utilityType: json['utility_type'] ?? '',
      category: json['category'] ?? 'residential',
      ratePerUnit: _parseDouble(json['rate_per_unit']),
      unit: json['unit'] ?? 'kWh',
      minCharge: json['min_charge'] != null
          ? _parseDouble(json['min_charge'])
          : null,
    );
  }
}
