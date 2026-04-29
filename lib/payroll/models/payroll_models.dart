// lib/payroll/models/payroll_models.dart
import '../../team/models/team_models.dart' show Employee;

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

// ---------------------------------------------------------------------------
// PayrollStatus
// ---------------------------------------------------------------------------
enum PayrollStatus { draft, approved, paid }

PayrollStatus _parsePayrollStatus(dynamic v) {
  if (v == null) return PayrollStatus.draft;
  final s = v.toString().toLowerCase();
  for (final ps in PayrollStatus.values) {
    if (ps.name == s) return ps;
  }
  return PayrollStatus.draft;
}

String payrollStatusLabel(PayrollStatus s, {bool swahili = false}) {
  switch (s) {
    case PayrollStatus.draft:
      return swahili ? 'Rasimu' : 'Draft';
    case PayrollStatus.approved:
      return swahili ? 'Imeidhinishwa' : 'Approved';
    case PayrollStatus.paid:
      return swahili ? 'Imelipwa' : 'Paid';
  }
}

// ---------------------------------------------------------------------------
// PayrollEntry
// ---------------------------------------------------------------------------
class PayrollEntry {
  final int? employeeId;
  final String employeeName;
  final double grossSalary;
  final double paye;
  final double nssfEmployee;
  final double nssfEmployer;
  final double sdl;
  final double wcf;
  final double netSalary;

  PayrollEntry({
    this.employeeId,
    this.employeeName = '',
    this.grossSalary = 0,
    this.paye = 0,
    this.nssfEmployee = 0,
    this.nssfEmployer = 0,
    this.sdl = 0,
    this.wcf = 0,
    this.netSalary = 0,
  });

  factory PayrollEntry.fromJson(Map<String, dynamic> json) {
    return PayrollEntry(
      employeeId: _parseInt(json['employee_id']),
      employeeName: json['employee_name']?.toString() ?? '',
      grossSalary: _parseDouble(json['gross_salary']),
      paye: _parseDouble(json['paye']),
      nssfEmployee: _parseDouble(json['nssf_employee']),
      nssfEmployer: _parseDouble(json['nssf_employer']),
      sdl: _parseDouble(json['sdl']),
      wcf: _parseDouble(json['wcf']),
      netSalary: _parseDouble(json['net_salary']),
    );
  }

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'gross_salary': grossSalary,
        'paye': paye,
        'nssf_employee': nssfEmployee,
        'nssf_employer': nssfEmployer,
        'sdl': sdl,
        'wcf': wcf,
        'net_salary': netSalary,
      };

  double get totalEmployerCost => grossSalary + nssfEmployer + sdl + wcf;
}

// ---------------------------------------------------------------------------
// PayrollRun
// ---------------------------------------------------------------------------
class PayrollRun {
  final int? id;
  final int? businessId;
  final int month;
  final int year;
  final List<PayrollEntry> employees;
  final double totalGross;
  final double totalNet;
  final double totalPaye;
  final double totalNssf;
  final double totalSdl;
  final double totalWcf;
  final PayrollStatus status;
  final DateTime? createdAt;

  PayrollRun({
    this.id,
    this.businessId,
    this.month = 1,
    this.year = 2026,
    this.employees = const [],
    this.totalGross = 0,
    this.totalNet = 0,
    this.totalPaye = 0,
    this.totalNssf = 0,
    this.totalSdl = 0,
    this.totalWcf = 0,
    this.status = PayrollStatus.draft,
    this.createdAt,
  });

  factory PayrollRun.fromJson(Map<String, dynamic> json) {
    List<PayrollEntry> emps = [];
    if (json['employees'] is List) {
      emps = (json['employees'] as List)
          .map((e) => PayrollEntry.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
    }
    return PayrollRun(
      id: _parseInt(json['id']),
      businessId: _parseInt(json['business_id']),
      month: _parseInt(json['month']) ?? 1,
      year: _parseInt(json['year']) ?? 2026,
      employees: emps,
      totalGross: _parseDouble(json['total_gross']),
      totalNet: _parseDouble(json['total_net']),
      totalPaye: _parseDouble(json['total_paye']),
      totalNssf: _parseDouble(json['total_nssf']),
      totalSdl: _parseDouble(json['total_sdl']),
      totalWcf: _parseDouble(json['total_wcf']),
      status: _parsePayrollStatus(json['status']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'business_id': businessId,
        'month': month,
        'year': year,
        'employees': employees.map((e) => e.toJson()).toList(),
        'total_gross': totalGross,
        'total_net': totalNet,
        'total_paye': totalPaye,
        'total_nssf': totalNssf,
        'total_sdl': totalSdl,
        'total_wcf': totalWcf,
        'status': status.name,
      };
}

// ---------------------------------------------------------------------------
// TanzaniaPAYE
// ---------------------------------------------------------------------------
class TanzaniaPAYE {
  static double calculateMonthlyPAYE(double grossMonthly) {
    if (grossMonthly <= 270000) return 0;

    double paye = 0;

    if (grossMonthly > 1000000) {
      paye += (grossMonthly - 1000000) * 0.30;
      paye += (1000000 - 760000) * 0.25;
      paye += (760000 - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else if (grossMonthly > 760000) {
      paye += (grossMonthly - 760000) * 0.25;
      paye += (760000 - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else if (grossMonthly > 520000) {
      paye += (grossMonthly - 520000) * 0.20;
      paye += (520000 - 270000) * 0.08;
    } else {
      paye += (grossMonthly - 270000) * 0.08;
    }

    return paye;
  }

  static double nssfEmployee(double gross) => gross * 0.10;
  static double nssfEmployer(double gross) => gross * 0.10;
  static double sdl(double gross) => gross * 0.035;
  static double wcf(double gross) => gross * 0.005;

  static double netSalary(double gross) {
    return gross - calculateMonthlyPAYE(gross) - nssfEmployee(gross);
  }

  static double totalEmployerCost(double gross) {
    return gross + nssfEmployer(gross) + sdl(gross) + wcf(gross);
  }

  static PayrollEntry buildPayrollEntry(Employee emp) {
    final gross = emp.grossSalary;
    return PayrollEntry(
      employeeId: emp.id,
      employeeName: emp.name,
      grossSalary: gross,
      paye: calculateMonthlyPAYE(gross),
      nssfEmployee: nssfEmployee(gross),
      nssfEmployer: nssfEmployer(gross),
      sdl: sdl(gross),
      wcf: wcf(gross),
      netSalary: netSalary(gross),
    );
  }
}

// ---------------------------------------------------------------------------
// StatutoryObligation
// ---------------------------------------------------------------------------
class StatutoryObligation {
  final int? id;
  final String type; // 'PAYE' | 'NSSF' | 'SDL' | 'WCF'
  final int month;
  final int year;
  final double amount;
  final bool remitted;
  final DateTime? dueDate;
  final DateTime? remittedAt;

  StatutoryObligation({
    this.id,
    required this.type,
    required this.month,
    required this.year,
    required this.amount,
    this.remitted = false,
    this.dueDate,
    this.remittedAt,
  });

  factory StatutoryObligation.fromJson(Map<String, dynamic> json) {
    return StatutoryObligation(
      id: _parseInt(json['id']),
      type: json['type']?.toString() ?? 'PAYE',
      month: _parseInt(json['month']) ?? 1,
      year: _parseInt(json['year']) ?? DateTime.now().year,
      amount: _parseDouble(json['amount']),
      remitted: _parseBool(json['remitted']),
      dueDate: _parseDate(json['due_date']),
      remittedAt: _parseDate(json['remitted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'month': month,
        'year': year,
        'amount': amount,
        'remitted': remitted,
        'due_date': dueDate?.toIso8601String(),
        'remitted_at': remittedAt?.toIso8601String(),
      };
}
