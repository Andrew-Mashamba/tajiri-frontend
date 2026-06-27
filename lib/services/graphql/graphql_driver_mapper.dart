import '../../shop/delivery/models/tajiri_delivery_models.dart';

/// Maps greenfield GraphQL Tajiri delivery types → legacy REST JSON / models.
class GraphqlDriverMapper {
  static Map<String, dynamic> jobToLegacy(Map<String, dynamic> gql) {
    final pickup = gql['pickup'] as Map<String, dynamic>? ?? {};
    final dropoff = gql['dropoff'] as Map<String, dynamic>? ?? {};
    final driver = gql['driver'] as Map<String, dynamic>?;

    return {
      'id': int.tryParse(gql['id']?.toString() ?? '') ?? 0,
      'job_number': gql['jobNumber'] ?? '',
      'status': gql['status'] ?? 'pending',
      if (gql['driverId'] != null) 'driver_id': int.tryParse(gql['driverId'].toString()),
      'pickup': {
        'name': pickup['name'] ?? '',
        'phone': pickup['phone'] ?? '',
        'address': pickup['address'] ?? '',
        if (pickup['lat'] != null) 'lat': pickup['lat'],
        if (pickup['lng'] != null) 'lng': pickup['lng'],
      },
      'dropoff': {
        'name': dropoff['name'] ?? '',
        'phone': dropoff['phone'] ?? '',
        'address': dropoff['address'] ?? '',
        if (dropoff['lat'] != null) 'lat': dropoff['lat'],
        if (dropoff['lng'] != null) 'lng': dropoff['lng'],
      },
      'quoted_price_tzs': gql['quotedPriceTzs'] ?? 0,
      'weight_kg': gql['weightKg'] ?? 1,
      'item_value_tzs': gql['itemValueTzs'] ?? 0,
      if (gql['notes'] != null) 'notes': gql['notes'],
      if (driver != null) 'driver': {
        if (driver['name'] != null) 'name': driver['name'],
        if (driver['phone'] != null) 'phone': driver['phone'],
        if (driver['vehicleType'] != null) 'vehicle_type': driver['vehicleType'],
        if (driver['vehiclePlate'] != null) 'vehicle_plate': driver['vehiclePlate'],
        if (driver['lat'] != null) 'lat': driver['lat'],
        if (driver['lng'] != null) 'lng': driver['lng'],
        if (driver['rating'] != null) 'rating': driver['rating'],
      },
      'payment_method': gql['paymentMethod'] ?? 'wallet',
      'order_total_tzs': gql['orderTotalTzs'] ?? 0,
      'cod_cash_collected': gql['codCashCollected'] ?? false,
      'created_at': gql['createdAt']?.toString(),
      'updated_at': gql['updatedAt']?.toString(),
    };
  }

  static TajiriDeliveryJob jobFromGraphql(Map<String, dynamic> gql) {
    return TajiriDeliveryJob.fromJson(jobToLegacy(gql));
  }

  static Map<String, dynamic> earningsToLegacy(Map<String, dynamic> gql) {
    final recent = (gql['recentJobs'] as List? ?? [])
        .map((j) => jobToLegacy(j as Map<String, dynamic>))
        .toList();
    return {
      'total': gql['total'] ?? 0,
      'today': gql['today'] ?? 0,
      'week': gql['week'] ?? 0,
      'month': gql['month'] ?? 0,
      'recent_jobs': recent,
    };
  }
}
