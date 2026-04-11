// lib/tanesco/models/tanesco_models.dart

int _parseInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
double _parseDouble(dynamic v) => (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
bool _parseBool(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

class SingleResult<T> { final bool success; final T? data; final String? message; SingleResult({required this.success, this.data, this.message}); }
class PaginatedResult<T> { final bool success; final List<T> items; final String? message; final int currentPage; final int lastPage;
  PaginatedResult({required this.success, this.items = const [], this.message, this.currentPage = 1, this.lastPage = 1}); bool get hasMore => currentPage < lastPage; }

class Meter {
  final int id; final String meterNumber; final String type; // prepaid, postpaid
  final String? alias; final double balance; final String? tariffCategory;
  final bool autoRechargeEnabled; final double? autoRechargeThreshold; final double? autoRechargeAmount;
  Meter({required this.id, required this.meterNumber, required this.type,
    this.alias, this.balance = 0, this.tariffCategory,
    this.autoRechargeEnabled = false, this.autoRechargeThreshold, this.autoRechargeAmount});
  factory Meter.fromJson(Map<String, dynamic> json) => Meter(
    id: _parseInt(json['id']), meterNumber: json['meter_number'] ?? '',
    type: json['type'] ?? 'prepaid', alias: json['alias'],
    balance: _parseDouble(json['balance']), tariffCategory: json['tariff_category'],
    autoRechargeEnabled: _parseBool(json['auto_recharge_enabled']),
    autoRechargeThreshold: json['auto_recharge_threshold'] != null ? _parseDouble(json['auto_recharge_threshold']) : null,
    autoRechargeAmount: json['auto_recharge_amount'] != null ? _parseDouble(json['auto_recharge_amount']) : null);
  bool get isLowBalance => type == 'prepaid' && balance < 10;
}

class TokenPurchase {
  final int id; final String meterNumber; final double amount; final double units;
  final String? token; final String paymentMethod; final DateTime purchasedAt;
  final String status; final String? selcomReference;
  TokenPurchase({required this.id, required this.meterNumber, required this.amount,
    required this.units, this.token, required this.paymentMethod,
    required this.purchasedAt, required this.status, this.selcomReference});
  factory TokenPurchase.fromJson(Map<String, dynamic> json) => TokenPurchase(
    id: _parseInt(json['id']), meterNumber: json['meter_number'] ?? '',
    amount: _parseDouble(json['amount']), units: _parseDouble(json['units']),
    token: json['token'], paymentMethod: json['payment_method'] ?? '',
    purchasedAt: DateTime.tryParse(json['purchased_at'] ?? '') ?? DateTime.now(),
    status: json['status'] ?? '', selcomReference: json['selcom_reference']);
}

class Outage {
  final int id; final String? location; final DateTime reportedAt;
  final String status; // reported, acknowledged, crewDispatched, fixed
  final int reporterCount;
  Outage({required this.id, this.location, required this.reportedAt,
    required this.status, this.reporterCount = 0});
  factory Outage.fromJson(Map<String, dynamic> json) => Outage(
    id: _parseInt(json['id']), location: json['location'],
    reportedAt: DateTime.tryParse(json['reported_at'] ?? '') ?? DateTime.now(),
    status: json['status'] ?? '', reporterCount: _parseInt(json['reporter_count']));
}

class Bill {
  final int id; final String meterNumber; final String billingPeriod;
  final double consumption; final double amount; final DateTime dueDate; final String status;
  Bill({required this.id, required this.meterNumber, required this.billingPeriod,
    required this.consumption, required this.amount, required this.dueDate, required this.status});
  factory Bill.fromJson(Map<String, dynamic> json) => Bill(
    id: _parseInt(json['id']), meterNumber: json['meter_number'] ?? '',
    billingPeriod: json['billing_period'] ?? '',
    consumption: _parseDouble(json['consumption']), amount: _parseDouble(json['amount']),
    dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
    status: json['status'] ?? 'unpaid');
  bool get isOverdue => status == 'overdue';
  bool get isPaid => status == 'paid';
}

class Balance {
  final String meterNumber; final double units; final DateTime lastUpdated;
  Balance({required this.meterNumber, required this.units, required this.lastUpdated});
  factory Balance.fromJson(Map<String, dynamic> json) => Balance(
    meterNumber: json['meter_number'] ?? '',
    units: _parseDouble(json['units']),
    lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now());
}

class ConsumptionRecord {
  final DateTime date; final double unitsUsed; final double cost;
  ConsumptionRecord({required this.date, required this.unitsUsed, required this.cost});
  factory ConsumptionRecord.fromJson(Map<String, dynamic> json) => ConsumptionRecord(
    date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
    unitsUsed: _parseDouble(json['units_used']),
    cost: _parseDouble(json['cost']));
}

class PlannedMaintenance {
  final int id; final String area; final DateTime startDate; final DateTime endDate;
  final String description;
  PlannedMaintenance({required this.id, required this.area, required this.startDate,
    required this.endDate, required this.description});
  factory PlannedMaintenance.fromJson(Map<String, dynamic> json) => PlannedMaintenance(
    id: _parseInt(json['id']), area: json['area'] ?? '',
    startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
    endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
    description: json['description'] ?? '');
}

class ConnectionApplication {
  final int id; final String type; // domestic, commercial, industrial
  final String status; // applied, surveyed, approved, materials, connected
  final String location; final List<String> documents; final DateTime appliedAt;
  final String? referenceNumber;
  ConnectionApplication({required this.id, required this.type, required this.status,
    required this.location, this.documents = const [], required this.appliedAt, this.referenceNumber});
  factory ConnectionApplication.fromJson(Map<String, dynamic> json) => ConnectionApplication(
    id: _parseInt(json['id']), type: json['type'] ?? 'domestic',
    status: json['status'] ?? 'applied', location: json['location'] ?? '',
    documents: (json['documents'] as List?)?.map((d) => '$d').toList() ?? [],
    appliedAt: DateTime.tryParse(json['applied_at'] ?? '') ?? DateTime.now(),
    referenceNumber: json['reference_number']);
}

class AutoRechargeConfig {
  final String meterNumber; final double threshold; final double rechargeAmount; final bool enabled;
  AutoRechargeConfig({required this.meterNumber, required this.threshold,
    required this.rechargeAmount, required this.enabled});
  factory AutoRechargeConfig.fromJson(Map<String, dynamic> json) => AutoRechargeConfig(
    meterNumber: json['meter_number'] ?? '',
    threshold: _parseDouble(json['threshold']),
    rechargeAmount: _parseDouble(json['recharge_amount']),
    enabled: _parseBool(json['enabled']));
}

class Appliance {
  final String name; final IconLabel icon; final double wattsPerHour;
  Appliance({required this.name, required this.icon, required this.wattsPerHour});
  factory Appliance.fromJson(Map<String, dynamic> json) => Appliance(
    name: json['name'] ?? '',
    icon: IconLabel.values.firstWhere((e) => e.name == json['icon'], orElse: () => IconLabel.other),
    wattsPerHour: _parseDouble(json['watts_per_hour']));
}

enum IconLabel { fridge, tv, iron, ac, bulb, fan, microwave, washingMachine, computer, waterHeater, other }

class ErrorCode {
  final String code; final String description; final String solution;
  ErrorCode({required this.code, required this.description, required this.solution});
  factory ErrorCode.fromJson(Map<String, dynamic> json) => ErrorCode(
    code: json['code'] ?? '', description: json['description'] ?? '',
    solution: json['solution'] ?? '');
}

class EnergyTip {
  final String title; final String description; final String? savingsEstimate; final String category;
  EnergyTip({required this.title, required this.description, this.savingsEstimate, required this.category});
  factory EnergyTip.fromJson(Map<String, dynamic> json) => EnergyTip(
    title: json['title'] ?? '', description: json['description'] ?? '',
    savingsEstimate: json['savings_estimate'], category: json['category'] ?? 'general');
}
