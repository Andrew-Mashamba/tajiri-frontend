class FoodRun {
  final int id;
  final int listingId;
  final int? reservationId;
  final int chefUserId;
  final int? orgId;
  final int? runnerUserId;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int portions;
  final double? distanceKm;
  final String? ward;
  final String status;
  final DateTime? claimedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? releaseReason;

  final String? orgName;
  final String? orgType;
  final String? chefName;

  FoodRun({
    required this.id,
    required this.listingId,
    required this.reservationId,
    required this.chefUserId,
    required this.orgId,
    required this.runnerUserId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.portions,
    required this.distanceKm,
    required this.ward,
    required this.status,
    required this.claimedAt,
    required this.pickedUpAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.releaseReason,
    required this.orgName,
    required this.orgType,
    required this.chefName,
  });

  bool get isUnclaimed => status == 'unclaimed';
  bool get isClaimed => status == 'claimed';
  bool get isPickingUp => status == 'picking_up';
  bool get isDelivered => status == 'delivered';

  factory FoodRun.fromJson(Map<String, dynamic> json) {
    return FoodRun(
      id: _parseInt(json['id']) ?? 0,
      listingId: _parseInt(json['listing_id']) ?? 0,
      reservationId: _parseInt(json['reservation_id']),
      chefUserId: _parseInt(json['chef_user_id']) ?? 0,
      orgId: _parseInt(json['org_id']),
      runnerUserId: _parseInt(json['runner_user_id']),
      pickupAddress: json['pickup_address']?.toString(),
      dropoffAddress: json['dropoff_address']?.toString(),
      pickupLat: _parseDouble(json['pickup_lat']),
      pickupLng: _parseDouble(json['pickup_lng']),
      dropoffLat: _parseDouble(json['dropoff_lat']),
      dropoffLng: _parseDouble(json['dropoff_lng']),
      portions: _parseInt(json['portions']) ?? 0,
      distanceKm: _parseDouble(json['distance_km']),
      ward: json['ward']?.toString(),
      status: json['status']?.toString() ?? 'unclaimed',
      claimedAt: _parseDate(json['claimed_at']),
      pickedUpAt: _parseDate(json['picked_up_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      cancelledAt: _parseDate(json['cancelled_at']),
      releaseReason: json['release_reason']?.toString(),
      orgName: json['org_name']?.toString(),
      orgType: json['org_type']?.toString(),
      chefName: json['chef_name']?.toString(),
    );
  }
}

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
