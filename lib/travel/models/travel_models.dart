// lib/travel/models/travel_models.dart

// ─── Enums ────────────────────────────────────────────────────

enum TransportMode {
  bus, flight, train, ferry;

  String get displayName {
    switch (this) {
      case TransportMode.bus: return 'Basi';
      case TransportMode.flight: return 'Ndege';
      case TransportMode.train: return 'Treni';
      case TransportMode.ferry: return 'Feri';
    }
  }

  String get subtitle {
    switch (this) {
      case TransportMode.bus: return 'Bus';
      case TransportMode.flight: return 'Flight';
      case TransportMode.train: return 'Train';
      case TransportMode.ferry: return 'Ferry';
    }
  }

  static TransportMode fromString(String? s) {
    final v = s?.toLowerCase() ?? '';
    for (final m in TransportMode.values) {
      if (m.name == v) return m;
    }
    return TransportMode.bus;
  }
}

enum BookingStatus {
  pending, confirmed, cancelled, completed;

  String get displayName {
    switch (this) {
      case BookingStatus.pending: return 'Pending';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.completed: return 'Completed';
    }
  }

  static BookingStatus fromString(String? s) {
    final v = s?.toLowerCase() ?? '';
    for (final b in BookingStatus.values) {
      if (b.name == v) return b;
    }
    return BookingStatus.pending;
  }
}

enum PaymentMethod {
  wallet, mpesa, tigopesa, airtelmoney;

  String get displayName {
    switch (this) {
      case PaymentMethod.wallet: return 'TAJIRI Wallet';
      case PaymentMethod.mpesa: return 'M-Pesa';
      case PaymentMethod.tigopesa: return 'Tigo Pesa';
      case PaymentMethod.airtelmoney: return 'Airtel Money';
    }
  }
}

// ─── Models ───────────────────────────────────────────────────

class TransportOperator {
  final String name;
  final String? code;
  final String? logo;

  const TransportOperator({required this.name, this.code, this.logo});

  factory TransportOperator.fromJson(Map<String, dynamic> json) {
    return TransportOperator(
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      logo: json['logo']?.toString(),
    );
  }
}

class TransportStop {
  final String city;
  final String? station;
  final String code;

  const TransportStop({required this.city, this.station, required this.code});

  factory TransportStop.fromJson(Map<String, dynamic> json) {
    return TransportStop(
      city: json['city']?.toString() ?? '',
      station: json['station']?.toString(),
      code: json['code']?.toString() ?? '',
    );
  }
}

class TransportPrice {
  final double amount;
  final String currency;

  const TransportPrice({required this.amount, this.currency = 'TZS'});

  factory TransportPrice.fromJson(Map<String, dynamic> json) {
    return TransportPrice(
      amount: _parseDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'TZS',
    );
  }

  String get formatted {
    if (amount >= 1000) {
      return '$currency ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},')}';
    }
    return '$currency ${amount.toStringAsFixed(0)}';
  }
}

class TransportOption {
  final String id;
  final TransportMode mode;
  final TransportOperator operator;
  final TransportStop origin;
  final TransportStop destination;
  final DateTime departure;
  final DateTime arrival;
  final int duration; // minutes
  final TransportPrice price;
  final String? transportClass;
  final int seatsAvailable;
  final String provider;

  // Mode-specific
  final String? flightNumber;
  final int? stops;
  final int? baggageKg;
  final String? busType;
  final List<String> amenities;
  final String? trainNumber;
  final String? trainType;
  final String? vesselName;
  final String? vehicleInfo;

  const TransportOption({
    required this.id,
    required this.mode,
    required this.operator,
    required this.origin,
    required this.destination,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
    this.transportClass,
    this.seatsAvailable = 0,
    this.provider = '',
    this.flightNumber,
    this.stops,
    this.baggageKg,
    this.busType,
    this.amenities = const [],
    this.trainNumber,
    this.trainType,
    this.vesselName,
    this.vehicleInfo,
  });

  String get durationFormatted {
    final h = duration ~/ 60;
    final m = duration % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  factory TransportOption.fromJson(Map<String, dynamic> json) {
    return TransportOption(
      id: json['id']?.toString() ?? '',
      mode: TransportMode.fromString(json['mode']?.toString()),
      operator: TransportOperator.fromJson(json['operator'] as Map<String, dynamic>? ?? {}),
      origin: TransportStop.fromJson(json['origin'] as Map<String, dynamic>? ?? {}),
      destination: TransportStop.fromJson(json['destination'] as Map<String, dynamic>? ?? {}),
      departure: DateTime.tryParse(json['departure']?.toString() ?? '') ?? DateTime.now(),
      arrival: DateTime.tryParse(json['arrival']?.toString() ?? '') ?? DateTime.now(),
      duration: _parseInt(json['duration']),
      price: TransportPrice.fromJson(json['price'] as Map<String, dynamic>? ?? {}),
      transportClass: json['class']?.toString(),
      seatsAvailable: _parseInt(json['seats_available']),
      provider: json['provider']?.toString() ?? '',
      flightNumber: json['flight_number']?.toString(),
      stops: json['stops'] != null ? _parseInt(json['stops']) : null,
      baggageKg: json['baggage_kg'] != null ? _parseInt(json['baggage_kg']) : null,
      busType: json['bus_type']?.toString(),
      amenities: _parseStringList(json['amenities']),
      trainNumber: json['train_number']?.toString(),
      trainType: json['train_type']?.toString(),
      vesselName: json['vessel_name']?.toString(),
      vehicleInfo: json['vehicle_info']?.toString(),
    );
  }
}

class City {
  final int id;
  final String name;
  final String code;
  final String? region;
  final String country;
  final bool hasAirport;
  final bool hasBusTerminal;
  final bool hasTrainStation;
  final bool hasFerryTerminal;

  const City({
    required this.id,
    required this.name,
    required this.code,
    this.region,
    this.country = 'TZ',
    this.hasAirport = false,
    this.hasBusTerminal = false,
    this.hasTrainStation = false,
    this.hasFerryTerminal = false,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      region: json['region']?.toString(),
      country: json['country']?.toString() ?? 'TZ',
      hasAirport: _parseBool(json['has_airport']),
      hasBusTerminal: _parseBool(json['has_bus_terminal']),
      hasTrainStation: _parseBool(json['has_train_station']),
      hasFerryTerminal: _parseBool(json['has_ferry_terminal']),
    );
  }
}

class PopularRoute {
  final TransportStop origin;
  final TransportStop destination;
  final List<String> modes;

  const PopularRoute({required this.origin, required this.destination, this.modes = const []});

  factory PopularRoute.fromJson(Map<String, dynamic> json) {
    return PopularRoute(
      origin: TransportStop.fromJson(json['origin'] as Map<String, dynamic>? ?? {}),
      destination: TransportStop.fromJson(json['destination'] as Map<String, dynamic>? ?? {}),
      modes: _parseStringList(json['modes']),
    );
  }
}

class Passenger {
  String name;
  String? phone;
  String? idType;  // nida, passport
  String? idNumber;

  Passenger({this.name = '', this.phone, this.idType, this.idNumber});

  Map<String, dynamic> toJson() => {
    'name': name,
    if (phone != null && phone!.isNotEmpty) 'phone': phone,
    if (idType != null) 'id_type': idType,
    if (idNumber != null && idNumber!.isNotEmpty) 'id_number': idNumber,
  };
}

class TransportBooking {
  final int id;
  final int userId;
  final String bookingReference;
  final String providerCode;
  final TransportMode mode;
  final String operator;
  final String originCity;
  final String destinationCity;
  final DateTime departure;
  final DateTime arrival;
  final int durationMinutes;
  final String? transportClass;
  final int passengerCount;
  final double unitPrice;
  final double totalAmount;
  final String currency;
  final BookingStatus status;
  final String? paymentMethod;
  final String? paymentStatus;
  final List<TransportPassenger> passengers;
  final TransportTicket? ticket;

  const TransportBooking({
    required this.id,
    required this.userId,
    required this.bookingReference,
    required this.providerCode,
    required this.mode,
    required this.operator,
    required this.originCity,
    required this.destinationCity,
    required this.departure,
    required this.arrival,
    required this.durationMinutes,
    this.transportClass,
    required this.passengerCount,
    required this.unitPrice,
    required this.totalAmount,
    this.currency = 'TZS',
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.passengers = const [],
    this.ticket,
  });

  bool get isUpcoming => departure.isAfter(DateTime.now()) && status != BookingStatus.cancelled;
  bool get isPast => departure.isBefore(DateTime.now()) || status == BookingStatus.completed;
  bool get canCancel => isUpcoming && status == BookingStatus.confirmed;

  factory TransportBooking.fromJson(Map<String, dynamic> json) {
    final paxList = json['passengers'] as List?;
    final ticketData = json['ticket'] as Map<String, dynamic>?;
    return TransportBooking(
      id: _parseInt(json['id']),
      userId: _parseInt(json['user_id']),
      bookingReference: json['booking_reference']?.toString() ?? '',
      providerCode: json['provider_code']?.toString() ?? '',
      mode: TransportMode.fromString(json['mode']?.toString()),
      operator: json['operator']?.toString() ?? '',
      originCity: json['origin_city']?.toString() ?? '',
      destinationCity: json['destination_city']?.toString() ?? '',
      departure: DateTime.tryParse(json['departure']?.toString() ?? '') ?? DateTime.now(),
      arrival: DateTime.tryParse(json['arrival']?.toString() ?? '') ?? DateTime.now(),
      durationMinutes: _parseInt(json['duration_minutes']),
      transportClass: json['class']?.toString(),
      passengerCount: _parseInt(json['passenger_count']),
      unitPrice: _parseDouble(json['unit_price']),
      totalAmount: _parseDouble(json['total_amount']),
      currency: json['currency']?.toString() ?? 'TZS',
      status: BookingStatus.fromString(json['status']?.toString()),
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
      passengers: paxList?.map((p) => TransportPassenger.fromJson(p as Map<String, dynamic>)).toList() ?? [],
      ticket: ticketData != null ? TransportTicket.fromJson(ticketData) : null,
    );
  }
}

class TransportPassenger {
  final int id;
  final String name;
  final String? phone;
  final String? idType;
  final String? idNumber;
  final bool isLead;

  const TransportPassenger({
    required this.id,
    required this.name,
    this.phone,
    this.idType,
    this.idNumber,
    this.isLead = false,
  });

  factory TransportPassenger.fromJson(Map<String, dynamic> json) {
    return TransportPassenger(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      idType: json['id_type']?.toString(),
      idNumber: json['id_number']?.toString(),
      isLead: _parseBool(json['is_lead']),
    );
  }
}

class TransportTicket {
  final int id;
  final int bookingId;
  final String ticketNumber;
  final String qrData;
  final String status;
  final Map<String, dynamic>? boardingInfo;

  const TransportTicket({
    required this.id,
    required this.bookingId,
    required this.ticketNumber,
    required this.qrData,
    this.status = 'active',
    this.boardingInfo,
  });

  factory TransportTicket.fromJson(Map<String, dynamic> json) {
    return TransportTicket(
      id: _parseInt(json['id']),
      bookingId: _parseInt(json['booking_id']),
      ticketNumber: json['ticket_number']?.toString() ?? '',
      qrData: json['qr_data']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      boardingInfo: json['boarding_info'] as Map<String, dynamic>?,
    );
  }
}

// ─── Result Wrappers ──────────────────────────────────────────

class TransportResult<T> {
  final bool success;
  final T? data;
  final String? message;

  TransportResult({required this.success, this.data, this.message});
}

class TransportListResult<T> {
  final bool success;
  final List<T> items;
  final String? message;

  TransportListResult({required this.success, this.items = const [], this.message});
}

// ─── Parse Helpers ────────────────────────────────────────────

int _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double _parseDouble(dynamic v) {
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool _parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return false;
}

List<String> _parseStringList(dynamic v) {
  if (v is List) return v.map((e) => e.toString()).toList();
  return [];
}
