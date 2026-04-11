// lib/dawasco/models/dawasco_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

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
  PaginatedResult({required this.success, this.items = const [], this.message, this.currentPage = 1, this.lastPage = 1});
  bool get hasMore => currentPage < lastPage;
}

class WaterAccount {
  final int id;
  final String accountNumber;
  final String? meterNumber;
  final String connectionType;
  final double balance;
  final String status;
  final String? wardId;
  final String? area;
  final String? ownerName;
  final String? phone;
  final String? address;

  WaterAccount({required this.id, required this.accountNumber, this.meterNumber,
    required this.connectionType, this.balance = 0, required this.status,
    this.wardId, this.area, this.ownerName, this.phone, this.address});

  factory WaterAccount.fromJson(Map<String, dynamic> json) => WaterAccount(
    id: _parseInt(json['id']),
    accountNumber: json['account_number'] ?? '',
    meterNumber: json['meter_number'],
    connectionType: json['connection_type'] ?? 'domestic',
    balance: _parseDouble(json['balance']),
    status: json['status'] ?? '',
    wardId: json['ward_id'],
    area: json['area'],
    ownerName: json['owner_name'],
    phone: json['phone'],
    address: json['address'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'account_number': accountNumber, 'meter_number': meterNumber,
    'connection_type': connectionType, 'balance': balance, 'status': status,
    'ward_id': wardId, 'area': area, 'owner_name': ownerName,
    'phone': phone, 'address': address,
  };
}

class WaterBill {
  final int id;
  final String billingPeriod;
  final double consumption;
  final double standingCharge;
  final double consumptionCharge;
  final double totalAmount;
  final DateTime dueDate;
  final String status;

  WaterBill({required this.id, required this.billingPeriod, required this.consumption,
    required this.standingCharge, required this.consumptionCharge,
    required this.totalAmount, required this.dueDate, required this.status});

  factory WaterBill.fromJson(Map<String, dynamic> json) => WaterBill(
    id: _parseInt(json['id']),
    billingPeriod: json['billing_period'] ?? '',
    consumption: _parseDouble(json['consumption']),
    standingCharge: _parseDouble(json['standing_charge']),
    consumptionCharge: _parseDouble(json['consumption_charge']),
    totalAmount: _parseDouble(json['total_amount']),
    dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
    status: json['status'] ?? 'unpaid',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'billing_period': billingPeriod, 'consumption': consumption,
    'standing_charge': standingCharge, 'consumption_charge': consumptionCharge,
    'total_amount': totalAmount, 'due_date': dueDate.toIso8601String(),
    'status': status,
  };

  bool get isOverdue => status == 'overdue';
  bool get isPaid => status == 'paid';
}

class ConsumptionRecord {
  final String month;
  final double consumptionM3;
  final double cost;

  ConsumptionRecord({required this.month, required this.consumptionM3, required this.cost});

  factory ConsumptionRecord.fromJson(Map<String, dynamic> json) => ConsumptionRecord(
    month: json['month'] ?? '',
    consumptionM3: _parseDouble(json['consumption_m3']),
    cost: _parseDouble(json['cost']),
  );

  Map<String, dynamic> toJson() => {
    'month': month, 'consumption_m3': consumptionM3, 'cost': cost,
  };
}

class SupplySchedule {
  final String dayOfWeek;
  final int startHour;
  final int endHour;
  final String? area;
  final String source;
  final double reliability;
  final String? status;

  SupplySchedule({required this.dayOfWeek, required this.startHour,
    required this.endHour, this.area, required this.source,
    this.reliability = 0, this.status});

  factory SupplySchedule.fromJson(Map<String, dynamic> json) => SupplySchedule(
    dayOfWeek: json['day_of_week'] ?? '',
    startHour: _parseInt(json['start_hour']),
    endHour: _parseInt(json['end_hour']),
    area: json['area'],
    source: json['source'] ?? 'official',
    reliability: _parseDouble(json['reliability']),
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    'day_of_week': dayOfWeek, 'start_hour': startHour, 'end_hour': endHour,
    'area': area, 'source': source, 'reliability': reliability, 'status': status,
  };
}

class SupplyStatus {
  final String area;
  final bool isAvailable;
  final String? reportedBy;
  final DateTime? reportedAt;
  final int reportsCount;

  SupplyStatus({required this.area, required this.isAvailable,
    this.reportedBy, this.reportedAt, this.reportsCount = 0});

  factory SupplyStatus.fromJson(Map<String, dynamic> json) => SupplyStatus(
    area: json['area'] ?? '',
    isAvailable: _parseBool(json['is_available']),
    reportedBy: json['reported_by'],
    reportedAt: DateTime.tryParse(json['reported_at'] ?? ''),
    reportsCount: _parseInt(json['reports_count']),
  );

  Map<String, dynamic> toJson() => {
    'area': area, 'is_available': isAvailable, 'reported_by': reportedBy,
    'reported_at': reportedAt?.toIso8601String(), 'reports_count': reportsCount,
  };
}

class WaterIssue {
  final int id;
  final String type; // leak, sewerage, quality, pressure
  final String? location;
  final String? description;
  final String severity;
  final String status; // reported, acknowledged, dispatched, fixed
  final DateTime reportedAt;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;

  WaterIssue({required this.id, required this.type, this.location, this.description,
    required this.severity, required this.status, required this.reportedAt,
    this.photoUrl, this.latitude, this.longitude});

  factory WaterIssue.fromJson(Map<String, dynamic> json) => WaterIssue(
    id: _parseInt(json['id']),
    type: json['type'] ?? '',
    location: json['location'],
    description: json['description'],
    severity: json['severity'] ?? 'medium',
    status: json['status'] ?? 'reported',
    reportedAt: DateTime.tryParse(json['reported_at'] ?? '') ?? DateTime.now(),
    photoUrl: json['photo_url'],
    latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
    longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'location': location, 'description': description,
    'severity': severity, 'status': status, 'reported_at': reportedAt.toIso8601String(),
    'photo_url': photoUrl, 'latitude': latitude, 'longitude': longitude,
  };
}

class ConnectionApplication {
  final int? id;
  final String type; // domestic, commercial, institutional
  final String status; // pending, reviewing, approved, connected, rejected
  final String? location;
  final String? ward;
  final List<String> documents;
  final DateTime? appliedAt;
  final double? connectionFee;

  ConnectionApplication({this.id, required this.type, required this.status,
    this.location, this.ward, this.documents = const [], this.appliedAt,
    this.connectionFee});

  factory ConnectionApplication.fromJson(Map<String, dynamic> json) => ConnectionApplication(
    id: json['id'] != null ? _parseInt(json['id']) : null,
    type: json['type'] ?? 'domestic',
    status: json['status'] ?? 'pending',
    location: json['location'],
    ward: json['ward'],
    documents: (json['documents'] as List?)?.map((e) => '$e').toList() ?? [],
    appliedAt: DateTime.tryParse(json['applied_at'] ?? ''),
    connectionFee: json['connection_fee'] != null ? _parseDouble(json['connection_fee']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'status': status, 'location': location,
    'ward': ward, 'documents': documents,
    'applied_at': appliedAt?.toIso8601String(), 'connection_fee': connectionFee,
  };
}

class WaterTariff {
  final String tier; // domestic, commercial, institutional
  final double minM3;
  final double maxM3;
  final double ratePerM3;
  final double? standingCharge;

  WaterTariff({required this.tier, required this.minM3, required this.maxM3,
    required this.ratePerM3, this.standingCharge});

  factory WaterTariff.fromJson(Map<String, dynamic> json) => WaterTariff(
    tier: json['tier'] ?? '',
    minM3: _parseDouble(json['min_m3']),
    maxM3: _parseDouble(json['max_m3']),
    ratePerM3: _parseDouble(json['rate_per_m3']),
    standingCharge: json['standing_charge'] != null ? _parseDouble(json['standing_charge']) : null,
  );

  Map<String, dynamic> toJson() => {
    'tier': tier, 'min_m3': minM3, 'max_m3': maxM3,
    'rate_per_m3': ratePerM3, 'standing_charge': standingCharge,
  };
}

class WaterTip {
  final int id;
  final String title;
  final String description;
  final String category; // kitchen, bathroom, garden, laundry, general
  final String? savingsEstimate;

  WaterTip({required this.id, required this.title, required this.description,
    required this.category, this.savingsEstimate});

  factory WaterTip.fromJson(Map<String, dynamic> json) => WaterTip(
    id: _parseInt(json['id']),
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? 'general',
    savingsEstimate: json['savings_estimate'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'category': category, 'savings_estimate': savingsEstimate,
  };
}

class EmergencyContact {
  final String name;
  final String phone;
  final String? description;

  EmergencyContact({required this.name, required this.phone, this.description});

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    description: json['description'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'phone': phone, 'description': description,
  };
}

class DawascoOffice {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final String? district;
  final double? latitude;
  final double? longitude;

  DawascoOffice({required this.id, required this.name, this.address, this.phone,
    this.district, this.latitude, this.longitude});

  factory DawascoOffice.fromJson(Map<String, dynamic> json) => DawascoOffice(
    id: _parseInt(json['id']),
    name: json['name'] ?? '',
    address: json['address'],
    phone: json['phone'],
    district: json['district'],
    latitude: json['latitude'] != null ? _parseDouble(json['latitude']) : null,
    longitude: json['longitude'] != null ? _parseDouble(json['longitude']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'address': address, 'phone': phone,
    'district': district, 'latitude': latitude, 'longitude': longitude,
  };
}

class WaterTanker {
  final int id;
  final String name;
  final String phone;
  final String? district;
  final double? pricePerTrip;
  final double? capacityLitres;

  WaterTanker({required this.id, required this.name, required this.phone,
    this.district, this.pricePerTrip, this.capacityLitres});

  factory WaterTanker.fromJson(Map<String, dynamic> json) => WaterTanker(
    id: _parseInt(json['id']),
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    district: json['district'],
    pricePerTrip: json['price_per_trip'] != null ? _parseDouble(json['price_per_trip']) : null,
    capacityLitres: json['capacity_litres'] != null ? _parseDouble(json['capacity_litres']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'phone': phone, 'district': district,
    'price_per_trip': pricePerTrip, 'capacity_litres': capacityLitres,
  };
}

class WaterQualityReport {
  final int id;
  final String area;
  final DateTime testDate;
  final String parameter; // pH, chlorine, turbidity, bacteria
  final double value;
  final String status; // safe, warning, unsafe
  final String? advisory;

  WaterQualityReport({required this.id, required this.area, required this.testDate,
    required this.parameter, required this.value, required this.status, this.advisory});

  factory WaterQualityReport.fromJson(Map<String, dynamic> json) => WaterQualityReport(
    id: _parseInt(json['id']),
    area: json['area'] ?? '',
    testDate: DateTime.tryParse(json['test_date'] ?? '') ?? DateTime.now(),
    parameter: json['parameter'] ?? '',
    value: _parseDouble(json['value']),
    status: json['status'] ?? 'safe',
    advisory: json['advisory'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'area': area, 'test_date': testDate.toIso8601String(),
    'parameter': parameter, 'value': value, 'status': status, 'advisory': advisory,
  };
}
