import '../../fuel_delivery/models/fuel_delivery_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL fuel delivery (Phase 66).
class GraphqlFuelDeliveryService {
  static const _priceFields = r'''
    fuelType
    pricePerLiter
    region
    effectiveDate
  ''';

  static const _orderFields = r'''
    id
    userId
    fuelType
    liters
    pricePerLiter
    deliveryFee
    totalCost
    status
    deliveryAddress
    latitude
    longitude
    specialInstructions
    carId
    carName
    scheduledAt
    createdAt
    driver {
      id
      name
      photoUrl
      rating
      phone
      vehiclePlate
    }
  ''';

  static Map<String, dynamic> _priceToLegacy(Map<String, dynamic> row) {
    return {
      'fuel_type': row['fuelType'],
      'price_per_liter': row['pricePerLiter'],
      'region': row['region'],
      'effective_date': row['effectiveDate'],
    };
  }

  static Map<String, dynamic> _orderToLegacy(Map<String, dynamic> row) {
    final driver = row['driver'] as Map<String, dynamic>?;
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'fuel_type': row['fuelType'],
      'liters': row['liters'],
      'price_per_liter': row['pricePerLiter'],
      'delivery_fee': row['deliveryFee'],
      'total_cost': row['totalCost'],
      'status': row['status'],
      'delivery_address': row['deliveryAddress'],
      'latitude': row['latitude'],
      'longitude': row['longitude'],
      'special_instructions': row['specialInstructions'],
      'car_id': row['carId'] != null ? int.parse(row['carId'].toString()) : null,
      'car_name': row['carName'],
      'scheduled_at': row['scheduledAt'],
      'created_at': row['createdAt'],
      if (driver != null)
        'driver': {
          'id': int.parse(driver['id'].toString()),
          'name': driver['name'],
          'photo_url': driver['photoUrl'],
          'rating': driver['rating'],
          'phone': driver['phone'],
          'vehicle_plate': driver['vehiclePlate'],
        },
    };
  }

  static Future<PaginatedResult<FuelPrice>> getFuelPrices({String? region}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FuelPrices(\$region: String) {
          fuelPrices(region: \$region) {
            $_priceFields
          }
        }
        ''',
        variables: {if (region != null) 'region': region},
        auth: true,
      );
      final rows = data['fuelPrices'] as List? ?? [];
      return PaginatedResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => FuelPrice.fromJson(_priceToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<FuelOrder>> placeOrder(
      Map<String, dynamic> body) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation PlaceFuelOrder(\$input: PlaceFuelOrderInput!) {
          placeFuelOrder(input: \$input) {
            $_orderFields
          }
        }
        ''',
        variables: {
          'input': {
            'fuelType': body['fuel_type'],
            'liters': body['liters'],
            if (body['delivery_address'] != null)
              'deliveryAddress': body['delivery_address'],
            if (body['latitude'] != null) 'latitude': body['latitude'],
            if (body['longitude'] != null) 'longitude': body['longitude'],
            if (body['special_instructions'] != null)
              'specialInstructions': body['special_instructions'],
            if (body['car_id'] != null) 'carId': '${body['car_id']}',
            if (body['car_name'] != null) 'carName': body['car_name'],
            if (body['scheduled_at'] != null) 'scheduledAt': body['scheduled_at'],
            if (body['region'] != null) 'region': body['region'],
            'paymentMethod': body['payment_method'] ?? 'wallet',
          },
        },
        auth: true,
      );
      final row = data['placeFuelOrder'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: FuelOrder.fromJson(_orderToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<PaginatedResult<FuelOrder>> getMyOrders({int page = 1}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyFuelOrders(\$page: Int, \$perPage: Int) {
          myFuelOrders(page: \$page, perPage: \$perPage) {
            currentPage
            lastPage
            total
            items {
              $_orderFields
            }
          }
        }
        ''',
        variables: {'page': page, 'perPage': 20},
        auth: true,
      );
      final conn = data['myFuelOrders'] as Map<String, dynamic>;
      final rows = conn['items'] as List? ?? [];
      return PaginatedResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => FuelOrder.fromJson(_orderToLegacy(row)))
            .toList(),
        currentPage: (conn['currentPage'] as num?)?.toInt() ?? page,
        lastPage: (conn['lastPage'] as num?)?.toInt() ?? 1,
      );
    } catch (e) {
      return PaginatedResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<FuelOrder>> getOrderDetail(int orderId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query FuelOrder(\$orderId: ID!) {
          fuelOrder(orderId: \$orderId) {
            $_orderFields
          }
        }
        ''',
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      final row = data['fuelOrder'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: FuelOrder.fromJson(_orderToLegacy(row)),
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<void>> cancelOrder(int orderId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelFuelOrder(\$orderId: ID!) {
          cancelFuelOrder(orderId: \$orderId)
        }
        ''',
        variables: {'orderId': orderId.toString()},
        auth: true,
      );
      return SingleResult(success: data['cancelFuelOrder'] == true);
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }

  static Future<SingleResult<double>> estimateDeliveryFee({
    required double latitude,
    required double longitude,
    required double liters,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation EstimateFuelDeliveryFee(\$input: EstimateFuelDeliveryFeeInput!) {
          estimateFuelDeliveryFee(input: \$input) {
            fee
          }
        }
        ''',
        variables: {
          'input': {
            'latitude': latitude,
            'longitude': longitude,
            'liters': liters,
          },
        },
        auth: true,
      );
      final row = data['estimateFuelDeliveryFee'] as Map<String, dynamic>;
      return SingleResult(
        success: true,
        data: (row['fee'] as num?)?.toDouble() ?? 0,
      );
    } catch (e) {
      return SingleResult(success: false, message: '$e');
    }
  }
}
