// lib/team/models/team_models.dart
// Data models for the Team (Employees) module.

int? _parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString());
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
  if (v is int) return v == 1;
  if (v is String) return v == '1' || v.toLowerCase() == 'true';
  return fallback;
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class Allowance {
  final String name;
  final double amount;

  const Allowance({required this.name, required this.amount});

  factory Allowance.fromJson(Map<String, dynamic> json) => Allowance(
        name: json['name']?.toString() ?? '',
        amount: _parseDouble(json['amount']),
      );

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount};
}

class PlatformUser {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;

  const PlatformUser({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory PlatformUser.fromJson(Map<String, dynamic> json) => PlatformUser(
        id: _parseInt(json['id']) ?? 0,
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        avatarUrl: json['profile_photo_url']?.toString(),
      );
}

class Employee {
  final int? id;
  final int? businessId;
  final int? userId;
  final String name;
  final String? phone;
  final String? nidaNumber;
  final String? position;
  final String? department;
  final String? contractType; // permanent | contract | part_time
  final double grossSalary;
  final bool applyPAYE;
  final bool applyNSSF;
  final bool applyNHIF;
  final List<Allowance> allowances;
  final DateTime? startDate;
  final String? bankAccount;
  final String? bankName;
  final bool isActive;

  const Employee({
    this.id,
    this.businessId,
    this.userId,
    required this.name,
    this.phone,
    this.nidaNumber,
    this.position,
    this.department,
    this.contractType,
    this.grossSalary = 0,
    this.applyPAYE = true,
    this.applyNSSF = true,
    this.applyNHIF = true,
    this.allowances = const [],
    this.startDate,
    this.bankAccount,
    this.bankName,
    this.isActive = true,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawAllowances = json['allowances'];
    final allowances = rawAllowances is List
        ? rawAllowances
            .whereType<Map<String, dynamic>>()
            .map(Allowance.fromJson)
            .toList()
        : <Allowance>[];
    return Employee(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      userId: _parseInt(json['user_id']),
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString(),
      nidaNumber: json['nida_number']?.toString(),
      position: json['position']?.toString(),
      department: json['department']?.toString(),
      contractType: json['contract_type']?.toString(),
      grossSalary: _parseDouble(json['gross_salary']),
      applyPAYE: _parseBool(json['apply_paye'], true),
      applyNSSF: _parseBool(json['apply_nssf'], true),
      applyNHIF: _parseBool(json['apply_nhif'], true),
      allowances: allowances,
      startDate: _parseDate(json['start_date']),
      bankAccount: json['bank_account']?.toString(),
      bankName: json['bank_name']?.toString(),
      isActive: _parseBool(json['is_active'], true),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'nida_number': nidaNumber,
        'position': position,
        'department': department,
        'contract_type': contractType,
        'gross_salary': grossSalary,
        'apply_paye': applyPAYE,
        'apply_nssf': applyNSSF,
        'apply_nhif': applyNHIF,
        'allowances': allowances.map((a) => a.toJson()).toList(),
        'start_date': startDate?.toIso8601String(),
        'bank_account': bankAccount,
        'bank_name': bankName,
        'is_active': isActive,
      };
}

class HrAction {
  final int? id;
  final int businessId;
  final int employeeId;
  final String actionType;
  final String category;
  final DateTime actionDate;
  final DateTime? effectiveDate;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String status;
  final int? createdBy;
  final DateTime? createdAt;

  const HrAction({
    this.id,
    required this.businessId,
    required this.employeeId,
    required this.actionType,
    required this.category,
    required this.actionDate,
    this.effectiveDate,
    this.description,
    this.metadata,
    this.status = 'active',
    this.createdBy,
    this.createdAt,
  });

  factory HrAction.fromJson(Map<String, dynamic> json) => HrAction(
        id: _parseInt(json['id']),
        businessId: _parseInt(json['business_id']) ?? 0,
        employeeId: _parseInt(json['employee_id']) ?? 0,
        actionType: json['action_type']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        actionDate: _parseDate(json['action_date']) ?? DateTime.now(),
        effectiveDate: _parseDate(json['effective_date']),
        description: json['description']?.toString(),
        metadata: json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : null,
        status: json['status']?.toString() ?? 'active',
        createdBy: _parseInt(json['created_by']),
        createdAt: _parseDate(json['created_at']),
      );

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'employee_id': employeeId,
        'action_type': actionType,
        'category': category,
        'action_date': actionDate.toIso8601String().substring(0, 10),
        if (effectiveDate != null)
          'effective_date': effectiveDate!.toIso8601String().substring(0, 10),
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
        'status': status,
        if (createdBy != null) 'created_by': createdBy,
      };
}
