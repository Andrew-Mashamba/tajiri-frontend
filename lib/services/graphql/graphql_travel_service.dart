import '../../travel/models/travel_models.dart';
import 'tajiri_graphql_client.dart';

/// GraphQL inter-city travel / transport (Phase 65).
class GraphqlTravelService {
  static const _optionFields = r'''
    id
    mode
    operator { name code logo }
    origin { city station code }
    destination { city station code }
    departure
    arrival
    duration
    price { amount currency }
    transportClass
    seatsAvailable
    provider
    flightNumber
    stops
    baggageKg
    busType
    amenities
    trainNumber
    trainType
    vesselName
    vehicleInfo
  ''';

  static const _cityFields = r'''
    id
    name
    code
    region
    country
    hasAirport
    hasBusTerminal
    hasTrainStation
    hasFerryTerminal
  ''';

  static const _bookingFields = r'''
    id
    userId
    bookingReference
    providerCode
    mode
    operator
    originCity
    destinationCity
    departure
    arrival
    durationMinutes
    transportClass
    passengerCount
    unitPrice
    totalAmount
    currency
    status
    paymentMethod
    paymentStatus
    passengers {
      id
      name
      phone
      idType
      idNumber
      isLead
    }
    ticket {
      id
      bookingId
      ticketNumber
      qrData
      status
      boardingInfo
    }
  ''';

  static const _ticketFields = r'''
    id
    bookingId
    ticketNumber
    qrData
    status
    boardingInfo
  ''';

  static Map<String, dynamic> _optionToLegacy(Map<String, dynamic> row) {
    final operator = row['operator'] as Map<String, dynamic>? ?? {};
    final origin = row['origin'] as Map<String, dynamic>? ?? {};
    final destination = row['destination'] as Map<String, dynamic>? ?? {};
    final price = row['price'] as Map<String, dynamic>? ?? {};
    return {
      'id': row['id']?.toString() ?? '',
      'mode': row['mode'],
      'operator': {
        'name': operator['name'],
        'code': operator['code'],
        'logo': operator['logo'],
      },
      'origin': {
        'city': origin['city'],
        'station': origin['station'],
        'code': origin['code'],
      },
      'destination': {
        'city': destination['city'],
        'station': destination['station'],
        'code': destination['code'],
      },
      'departure': row['departure'],
      'arrival': row['arrival'],
      'duration': row['duration'],
      'price': {
        'amount': price['amount'],
        'currency': price['currency'] ?? 'TZS',
      },
      'class': row['transportClass'],
      'seats_available': row['seatsAvailable'],
      'provider': row['provider'],
      'flight_number': row['flightNumber'],
      'stops': row['stops'],
      'baggage_kg': row['baggageKg'],
      'bus_type': row['busType'],
      'amenities': row['amenities'] ?? [],
      'train_number': row['trainNumber'],
      'train_type': row['trainType'],
      'vessel_name': row['vesselName'],
      'vehicle_info': row['vehicleInfo'],
    };
  }

  static Map<String, dynamic> _cityToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'name': row['name'],
      'code': row['code'],
      'region': row['region'],
      'country': row['country'] ?? 'TZ',
      'has_airport': row['hasAirport'] == true,
      'has_bus_terminal': row['hasBusTerminal'] == true,
      'has_train_station': row['hasTrainStation'] == true,
      'has_ferry_terminal': row['hasFerryTerminal'] == true,
    };
  }

  static Map<String, dynamic> _popularRouteToLegacy(Map<String, dynamic> row) {
    final origin = row['origin'] as Map<String, dynamic>? ?? {};
    final destination = row['destination'] as Map<String, dynamic>? ?? {};
    return {
      'origin': {
        'city': origin['city'],
        'station': origin['station'],
        'code': origin['code'],
      },
      'destination': {
        'city': destination['city'],
        'station': destination['station'],
        'code': destination['code'],
      },
      'modes': row['modes'] ?? [],
    };
  }

  static Map<String, dynamic> _bookingToLegacy(Map<String, dynamic> row) {
    final passengers = (row['passengers'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((p) => {
              'id': int.parse(p['id'].toString()),
              'name': p['name'],
              'phone': p['phone'],
              'id_type': p['idType'],
              'id_number': p['idNumber'],
              'is_lead': p['isLead'] == true,
            })
        .toList();
    final ticket = row['ticket'] as Map<String, dynamic>?;
    return {
      'id': int.parse(row['id'].toString()),
      'user_id': int.parse(row['userId'].toString()),
      'booking_reference': row['bookingReference'],
      'provider_code': row['providerCode'],
      'mode': row['mode'],
      'operator': row['operator'],
      'origin_city': row['originCity'],
      'destination_city': row['destinationCity'],
      'departure': row['departure'],
      'arrival': row['arrival'],
      'duration_minutes': row['durationMinutes'],
      'class': row['transportClass'],
      'passenger_count': row['passengerCount'],
      'unit_price': row['unitPrice'],
      'total_amount': row['totalAmount'],
      'currency': row['currency'] ?? 'TZS',
      'status': row['status'],
      'payment_method': row['paymentMethod'],
      'payment_status': row['paymentStatus'],
      'passengers': passengers,
      if (ticket != null) 'ticket': _ticketToLegacy(ticket),
    };
  }

  static Map<String, dynamic> _ticketToLegacy(Map<String, dynamic> row) {
    return {
      'id': int.parse(row['id'].toString()),
      'booking_id': int.parse(row['bookingId'].toString()),
      'ticket_number': row['ticketNumber'],
      'qr_data': row['qrData'],
      'status': row['status'],
      'boarding_info': row['boardingInfo'] as Map<String, dynamic>?,
    };
  }

  static Future<TransportListResult<TransportOption>> search({
    required String origin,
    required String destination,
    required String date,
    int passengers = 1,
    String? preferredMode,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation SearchTransportOptions(\$input: SearchTransportOptionsInput!) {
          searchTransportOptions(input: \$input) {
            $_optionFields
          }
        }
        ''',
        variables: {
          'input': {
            'origin': origin,
            'destination': destination,
            'date': date,
            'passengers': passengers,
            if (preferredMode != null) 'preferredMode': preferredMode,
          },
        },
        auth: false,
      );
      final rows = data['searchTransportOptions'] as List? ?? [];
      return TransportListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => TransportOption.fromJson(_optionToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return TransportListResult(success: false, message: '$e');
    }
  }

  static Future<TransportResult<TransportOption>> getOption(String optionId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TransportOption(\$optionId: ID!) {
          transportOption(optionId: \$optionId) {
            $_optionFields
          }
        }
        ''',
        variables: {'optionId': optionId},
        auth: false,
      );
      final row = data['transportOption'] as Map<String, dynamic>;
      return TransportResult(
        success: true,
        data: TransportOption.fromJson(_optionToLegacy(row)),
      );
    } catch (e) {
      return TransportResult(success: false, message: '$e');
    }
  }

  static Future<TransportListResult<City>> getCities({String? query}) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TransportCities(\$q: String) {
          transportCities(q: \$q) {
            $_cityFields
          }
        }
        ''',
        variables: {if (query != null && query.isNotEmpty) 'q': query},
        auth: false,
      );
      final rows = data['transportCities'] as List? ?? [];
      return TransportListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => City.fromJson(_cityToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return TransportListResult(success: false, message: '$e');
    }
  }

  static Future<TransportListResult<PopularRoute>> getPopularRoutes() async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TransportPopularRoutes {
          transportPopularRoutes {
            origin { city station code }
            destination { city station code }
            modes
          }
        }
        ''',
        auth: false,
      );
      final rows = data['transportPopularRoutes'] as List? ?? [];
      return TransportListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => PopularRoute.fromJson(_popularRouteToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return TransportListResult(success: false, message: '$e');
    }
  }

  static Future<TransportResult<TransportBooking>> createBooking({
    required String optionId,
    required int userId,
    required List<Passenger> passengers,
    required PaymentMethod paymentMethod,
    String? paymentPhone,
  }) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CreateTransportBooking(\$input: CreateTransportBookingInput!) {
          createTransportBooking(input: \$input) {
            $_bookingFields
          }
        }
        ''',
        variables: {
          'input': {
            'optionId': optionId,
            'passengers': passengers
                .map((p) => {
                      'name': p.name,
                      if (p.phone != null && p.phone!.isNotEmpty) 'phone': p.phone,
                      if (p.idType != null) 'idType': p.idType,
                      if (p.idNumber != null && p.idNumber!.isNotEmpty)
                        'idNumber': p.idNumber,
                    })
                .toList(),
            'paymentMethod': paymentMethod.name,
            if (paymentPhone != null && paymentPhone.isNotEmpty)
              'paymentPhone': paymentPhone,
          },
        },
        auth: true,
      );
      final row = data['createTransportBooking'] as Map<String, dynamic>;
      return TransportResult(
        success: true,
        data: TransportBooking.fromJson(_bookingToLegacy(row)),
      );
    } catch (e) {
      return TransportResult(success: false, message: '$e');
    }
  }

  static Future<TransportListResult<TransportBooking>> getBookings(int userId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query MyTransportBookings {
          myTransportBookings {
            $_bookingFields
          }
        }
        ''',
        auth: true,
      );
      final rows = data['myTransportBookings'] as List? ?? [];
      return TransportListResult(
        success: true,
        items: rows
            .whereType<Map<String, dynamic>>()
            .map((row) => TransportBooking.fromJson(_bookingToLegacy(row)))
            .toList(),
      );
    } catch (e) {
      return TransportListResult(success: false, message: '$e');
    }
  }

  static Future<TransportResult<TransportBooking>> cancelBooking(int bookingId) async {
    try {
      final data = await TajiriGraphqlClient.instance.mutate(
        '''
        mutation CancelTransportBooking(\$bookingId: ID!) {
          cancelTransportBooking(bookingId: \$bookingId) {
            $_bookingFields
          }
        }
        ''',
        variables: {'bookingId': bookingId.toString()},
        auth: true,
      );
      final row = data['cancelTransportBooking'] as Map<String, dynamic>;
      return TransportResult(
        success: true,
        data: TransportBooking.fromJson(_bookingToLegacy(row)),
      );
    } catch (e) {
      return TransportResult(success: false, message: '$e');
    }
  }

  static Future<TransportResult<TransportTicket>> getTicket(int bookingId) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TransportTicket(\$bookingId: ID!) {
          transportTicket(bookingId: \$bookingId) {
            $_ticketFields
          }
        }
        ''',
        variables: {'bookingId': bookingId.toString()},
        auth: true,
      );
      final row = data['transportTicket'] as Map<String, dynamic>;
      return TransportResult(
        success: true,
        data: TransportTicket.fromJson(_ticketToLegacy(row)),
      );
    } catch (e) {
      return TransportResult(success: false, message: '$e');
    }
  }

  static Future<TransportResult<Map<String, dynamic>>> getWeather(
      String cityCode) async {
    try {
      final data = await TajiriGraphqlClient.instance.query(
        '''
        query TransportCityWeather(\$cityCode: String!) {
          transportCityWeather(cityCode: \$cityCode)
        }
        ''',
        variables: {'cityCode': cityCode},
        auth: false,
      );
      final row = data['transportCityWeather'];
      if (row is Map<String, dynamic>) {
        return TransportResult(success: true, data: row);
      }
      return TransportResult(success: false, message: 'Invalid weather payload');
    } catch (e) {
      return TransportResult(success: false, message: '$e');
    }
  }
}
