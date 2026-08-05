// Tajiri Delivery — domain models for the in-house courier service.
// Both driver-facing and buyer/seller-facing screens use these models.

// ─── Helpers ──────────────────────────────────────────────────────────────

int _parseInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  return int.tryParse(v.toString()) ?? fallback;
}

double _parseDouble(dynamic v, [double fallback = 0.0]) {
  if (v == null) return fallback;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

bool _parseBool(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  return v.toString() == 'true' || v.toString() == '1';
}

// ─── TajiriDeliveryJob ────────────────────────────────────────────────────

class TajiriDeliveryJob {
  final int id;
  final String jobNumber;
  final String status;
  final int? driverId;

  // Pickup
  final String pickupName;
  final String pickupPhone;
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;

  // Dropoff
  final String dropoffName;
  final String dropoffPhone;
  final String dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;

  // Pricing & package
  final double quotedPriceTzs;
  final double weightKg;
  final double itemValueTzs;
  final String? notes;

  // Assigned driver info (populated once driver accepts)
  final String? driverName;
  final String? driverPhone;
  final String? vehicleType;
  final String? vehiclePlate;
  final double? driverLat;
  final double? driverLng;
  final double? driverRating;

  // Payment
  final String paymentMethod; // 'wallet' | 'cod'
  final double orderTotalTzs;
  final bool codCashCollected;

  // Timestamps
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TajiriDeliveryJob({
    required this.id,
    required this.jobNumber,
    required this.status,
    this.driverId,
    required this.pickupName,
    required this.pickupPhone,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    required this.dropoffName,
    required this.dropoffPhone,
    required this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    required this.quotedPriceTzs,
    this.weightKg = 1.0,
    this.itemValueTzs = 0,
    this.notes,
    this.driverName,
    this.driverPhone,
    this.vehicleType,
    this.vehiclePlate,
    this.driverLat,
    this.driverLng,
    this.driverRating,
    this.paymentMethod = 'wallet',
    this.orderTotalTzs = 0,
    this.codCashCollected = false,
    this.createdAt,
    this.updatedAt,
  });

  factory TajiriDeliveryJob.fromJson(Map<String, dynamic> j) {
    final pickup = j['pickup'] as Map<String, dynamic>? ?? {};
    final dropoff = j['dropoff'] as Map<String, dynamic>? ?? {};
    final driver = j['driver'] as Map<String, dynamic>? ?? {};

    return TajiriDeliveryJob(
      id: _parseInt(j['id']),
      jobNumber: j['job_number'] as String? ?? '#${j['id']}',
      status: j['status'] as String? ?? 'pending',
      driverId: j['driver_id'] != null ? _parseInt(j['driver_id']) : null,

      // Pickup
      pickupName: pickup['name'] as String? ?? j['pickup_name'] as String? ?? '',
      pickupPhone: pickup['phone'] as String? ?? j['pickup_phone'] as String? ?? '',
      pickupAddress: pickup['address'] as String? ?? j['pickup_address'] as String? ?? '',
      pickupLat: pickup['lat'] != null
          ? _parseDouble(pickup['lat'])
          : j['pickup_lat'] != null
              ? _parseDouble(j['pickup_lat'])
              : null,
      pickupLng: pickup['lng'] != null
          ? _parseDouble(pickup['lng'])
          : j['pickup_lng'] != null
              ? _parseDouble(j['pickup_lng'])
              : null,

      // Dropoff
      dropoffName: dropoff['name'] as String? ?? j['dropoff_name'] as String? ?? '',
      dropoffPhone: dropoff['phone'] as String? ?? j['dropoff_phone'] as String? ?? '',
      dropoffAddress: dropoff['address'] as String? ?? j['dropoff_address'] as String? ?? '',
      dropoffLat: dropoff['lat'] != null
          ? _parseDouble(dropoff['lat'])
          : j['dropoff_lat'] != null
              ? _parseDouble(j['dropoff_lat'])
              : null,
      dropoffLng: dropoff['lng'] != null
          ? _parseDouble(dropoff['lng'])
          : j['dropoff_lng'] != null
              ? _parseDouble(j['dropoff_lng'])
              : null,

      // Pricing & package
      quotedPriceTzs: _parseDouble(j['quoted_price_tzs']),
      weightKg: _parseDouble(j['weight_kg'], 1.0),
      itemValueTzs: _parseDouble(j['item_value_tzs']),
      notes: j['notes'] as String?,

      // Driver
      driverName: driver['name'] as String? ?? j['driver_name'] as String?,
      driverPhone: driver['phone'] as String? ?? j['driver_phone'] as String?,
      vehicleType: driver['vehicle_type'] as String? ?? j['vehicle_type'] as String?,
      vehiclePlate: driver['vehicle_plate'] as String? ?? j['vehicle_plate'] as String?,
      driverLat: driver['lat'] != null ? _parseDouble(driver['lat']) : null,
      driverLng: driver['lng'] != null ? _parseDouble(driver['lng']) : null,
      driverRating: driver['rating'] != null ? _parseDouble(driver['rating']) : null,

      // Payment info from linked order (backend embeds order.payment_method)
      paymentMethod: j['payment_method'] as String? ?? 'wallet',
      orderTotalTzs: _parseDouble(j['order_total_tzs']),
      codCashCollected: _parseBool(j['cod_cash_collected']),

      // Timestamps
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
    );
  }

  // ─── Helper getters ──────────────────────────────────────────────

  bool get isCod => paymentMethod == 'cod';

  bool get isPending => status == 'pending';
  bool get isAssigned => status == 'assigned';
  bool get isEnRoutePickup => status == 'en_route_pickup';
  bool get isPickedUp => status == 'picked_up';
  bool get isInTransit => status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get isFailed => status == 'failed';

  bool get isActive =>
      isAssigned || isEnRoutePickup || isPickedUp || isInTransit;

  bool get canConfirmPickup => isAssigned || isEnRoutePickup;
  bool get canConfirmDelivery => isPickedUp || isInTransit;

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Searching for driver';
      case 'assigned':
        return 'Driver assigned';
      case 'en_route_pickup':
        return 'Driver on the way';
      case 'picked_up':
        return 'Package picked up';
      case 'in_transit':
        return 'In transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }

  String get priceFormatted {
    if (quotedPriceTzs <= 0) return 'Free';
    return 'TZS ${quotedPriceTzs.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        )}';
  }
}

// ─── TajiriDriverProfile ──────────────────────────────────────────────────

class TajiriDriverProfile {
  final int id;
  final int userId;
  final String vehicleType;
  final String? vehiclePlate;
  final bool isOnline;
  final bool isVerified;
  final double rating;
  final int totalDeliveries;
  final double totalEarningsTzs;
  final String? name;
  final String? phone;
  final String? avatarUrl;

  const TajiriDriverProfile({
    required this.id,
    required this.userId,
    required this.vehicleType,
    this.vehiclePlate,
    required this.isOnline,
    required this.isVerified,
    required this.rating,
    required this.totalDeliveries,
    required this.totalEarningsTzs,
    this.name,
    this.phone,
    this.avatarUrl,
  });

  factory TajiriDriverProfile.fromJson(Map<String, dynamic> j) {
    return TajiriDriverProfile(
      id: _parseInt(j['id']),
      userId: _parseInt(j['user_id']),
      vehicleType: j['vehicle_type'] as String? ?? 'motorcycle',
      vehiclePlate: j['vehicle_plate'] as String?,
      isOnline: _parseBool(j['is_online']),
      isVerified: _parseBool(j['is_verified']),
      rating: _parseDouble(j['rating'], 5.0),
      totalDeliveries: _parseInt(j['total_deliveries']),
      totalEarningsTzs: _parseDouble(j['total_earnings_tzs']),
      name: j['name'] as String?,
      phone: j['phone'] as String?,
      avatarUrl: j['avatar_url'] as String?,
    );
  }

  String get vehicleTypeLabel {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return 'Motorcycle';
      case 'bicycle':
        return 'Bicycle';
      case 'car':
        return 'Car';
      case 'van':
        return 'Van';
      case 'truck':
        return 'Truck';
      default:
        return vehicleType;
    }
  }

  String get earningsFormatted {
    return 'TZS ${totalEarningsTzs.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (m) => ',',
        )}';
  }
}

// ─── DriverLocationUpdate ─────────────────────────────────────────────────
// Mirrors the Firebase Realtime Database structure at /driver_locations/{id}

class DriverLocationUpdate {
  final double lat;
  final double lng;
  final double heading;
  final int updatedAtMs;
  final int? jobId;
  final String? status;

  const DriverLocationUpdate({
    required this.lat,
    required this.lng,
    required this.heading,
    required this.updatedAtMs,
    this.jobId,
    this.status,
  });

  factory DriverLocationUpdate.fromMap(Map<Object?, Object?> m) {
    return DriverLocationUpdate(
      lat: _parseDouble(m['lat']),
      lng: _parseDouble(m['lng']),
      heading: _parseDouble(m['heading']),
      updatedAtMs: _parseInt(m['updated_at']),
      jobId: m['job_id'] != null ? _parseInt(m['job_id']) : null,
      status: m['status'] as String?,
    );
  }
}
